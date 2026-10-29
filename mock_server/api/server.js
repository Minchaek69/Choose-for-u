// Vercel 서버리스 함수: json-server 0.17.4를 "읽기 전용 GET"으로 띄운다. (가산점용)
// - 서버리스는 디스크에 쓸 수 없으므로 db.json은 메모리로만 읽고, GET 외 요청은 403으로 거절한다.
// - 주소: https://<프로젝트>.vercel.app/api/items  →  json-server의 /items
// 참고(MIT): https://github.com/kitloong/json-server-vercel — 구조만 참고해 최소 구성으로 다시 작성.
const path = require('path');
const fs = require('fs');
const jsonServer = require('json-server');

// 파일 경로 대신 "객체"를 넘겨야 json-server가 db.json에 다시 쓰지 않는다.
const data = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'db.json'), 'utf-8'),
);

const server = jsonServer.create();
const router = jsonServer.router(data);

server.use(jsonServer.defaults({ readOnly: true })); // CORS 허용 + GET 외 거절(403)
server.use(jsonServer.rewriter({ '/api/*': '/$1' })); // /api/items → /items
server.use(router);

module.exports = server;
