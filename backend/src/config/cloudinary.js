import { v2 as cloudinary } from 'cloudinary';
import multer from 'multer';
import { env } from './env.js';

cloudinary.config({
  cloud_name: env.cloudinary.cloudName,
  api_key: env.cloudinary.apiKey,
  api_secret: env.cloudinary.apiSecret,
  secure: true,
});

class CloudinaryStorage {
  constructor(folder) {
    this.folder = folder;
  }

  _handleFile(_req, file, callback) {
    let completed = false;
    const finish = (...result) => {
      if (completed) return;
      completed = true;
      callback(...result);
    };
    const upload = cloudinary.uploader.upload_stream(
      {
        folder: this.folder,
        resource_type: 'image',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
        transformation: [{ width: 800, height: 800, crop: 'limit', quality: 'auto' }],
      },
      (error, result) => {
        if (error) {
          finish(error);
          return;
        }
        if (!result) {
          finish(new Error('Cloudinary returned an empty upload result.'));
          return;
        }
        finish(null, {
          filename: result.public_id,
          path: result.secure_url,
          size: result.bytes,
        });
      },
    );
    file.stream.on('error', finish);
    file.stream.pipe(upload);
  }

  _removeFile(_req, file, callback) {
    if (!file.filename) {
      callback(null);
      return;
    }
    cloudinary.uploader
      .destroy(file.filename, { resource_type: 'image' })
      .then((result) => {
        if (!['ok', 'not found'].includes(result.result)) {
          callback(new Error('Cloudinary could not remove the uploaded image.'));
          return;
        }
        callback(null);
      })
      .catch(callback);
  }
}

function imageUpload(folder) {
  return multer({
    storage: new CloudinaryStorage(folder),
    limits: { fileSize: 5 * 1024 * 1024, files: 1 },
    fileFilter(_req, file, callback) {
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
        const error = new Error('Image must be a JPEG, PNG, or WebP file.');
        error.statusCode = 400;
        callback(error);
        return;
      }
      callback(null, true);
    },
  });
}

export const avatarUpload = imageUpload('nascon/avatars');
export const productImageUpload = imageUpload('nascon/products');

export { cloudinary };
