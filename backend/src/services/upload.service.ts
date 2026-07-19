import multer from "multer";
import fs from "fs";
import path from "path";

const storage = multer.diskStorage({
  destination(req, file, cb) {
    const folder =
      req.body.path || "/var/www";

    fs.mkdirSync(folder, {
      recursive: true,
    });

    cb(null, folder);
  },

  filename(req, file, cb) {
    cb(null, file.originalname);
  },
});

export default multer({
  storage,
});