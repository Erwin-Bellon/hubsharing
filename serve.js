const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const PUBLIC_DIR = path.join(__dirname, 'output');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.xml': 'application/xml; charset=utf-8',
  '.ttl': 'text/turtle; charset=utf-8'
};

const server = http.createServer((req, res) => {
  let reqPath = decodeURIComponent(req.url.split('?')[0]);
  if (reqPath === '/' || reqPath === '') {
    res.writeHead(302, { 'Location': '/en/index.html' });
    res.end();
    return;
  }

  let filePath = path.join(PUBLIC_DIR, reqPath);

  // Guard against path traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.statusCode = 403;
    res.end('403 Forbidden');
    return;
  }

  function tryServe(targetPath) {
    if (fs.existsSync(targetPath) && fs.statSync(targetPath).isFile()) {
      const ext = path.extname(targetPath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';
      res.setHeader('Content-Type', contentType);
      res.end(fs.readFileSync(targetPath));
      return true;
    }
    return false;
  }

  // 1. Direct file match
  if (tryServe(filePath)) return;

  // 2. Try with .html extension
  if (tryServe(filePath + '.html')) return;

  // 3. Try inside /en/ subdirectory
  const enPath = path.join(PUBLIC_DIR, 'en', reqPath.replace(/^\//, ''));
  if (tryServe(enPath)) return;
  if (tryServe(enPath + '.html')) return;

  // 4. Try index.html inside directory
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    if (tryServe(path.join(filePath, 'index.html'))) return;
  }

  // 404
  res.statusCode = 404;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end('<h1>404 Not Found</h1><p>The requested file was not found in the IG output build.</p><p><a href="/en/index.html">Go to IG Home</a></p>');
});

server.listen(PORT, () => {
  console.log(`Official HL7 FHIR IG Publisher site running at http://localhost:${PORT}/en/index.html`);
});
