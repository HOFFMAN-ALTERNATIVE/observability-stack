"""Stand-in dead-man's switch for CI: logs every POST path, answers 200."""

import http.server


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802 (stdlib naming)
        self.rfile.read(int(self.headers.get("content-length", 0)))
        print(f"POST {self.path}", flush=True)
        self.send_response(200)
        self.end_headers()

    def log_message(self, *args: object) -> None:
        pass


http.server.HTTPServer(("", 8080), Handler).serve_forever()
