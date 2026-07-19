import fs from "fs/promises";
import path from "path";

export async function createWebsiteDirectory(domain: string) {
  const websitePath = path.join("/var/www", domain);

  const folders = [
    "public",
    "logs",
    "uploads",
    "config",
    "ssl",
    "backups",
    "tmp",
  ];

  await fs.mkdir(websitePath, { recursive: true });

  for (const folder of folders) {
    await fs.mkdir(path.join(websitePath, folder), {
      recursive: true,
    });
  }

  const indexHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>${domain}</title>

<style>

body{

background:#0f172a;

font-family:Arial;

display:flex;

justify-content:center;

align-items:center;

height:100vh;

color:white;

margin:0;

}

.card{

background:#1e293b;

padding:50px;

border-radius:20px;

text-align:center;

box-shadow:0 0 25px rgba(0,0,0,.4);

}

h1{

color:#38bdf8;

}

</style>

</head>

<body>

<div class="card">

<h1>🚀 Codex Panel</h1>

<h2>${domain}</h2>

<p>Your website has been deployed successfully.</p>

<p>Edit files inside the <b>public</b> folder.</p>

</div>

</body>
</html>`;

  await fs.writeFile(
    path.join(websitePath, "public", "index.html"),
    indexHtml
  );

  await fs.writeFile(
    path.join(websitePath, "logs", "access.log"),
    ""
  );

  await fs.writeFile(
    path.join(websitePath, "logs", "error.log"),
    ""
  );

  return websitePath;
}