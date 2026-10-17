import { cloudinary } from '../config/cloudinary.js';

export function profile(req, res) {
  res.json({ user: req.user.toPublicJSON() });
}

export function currentUser(req, res) {
  res.json(req.user.toPublicJSON());
}

export async function logout(req, res) {
  req.user.tokenVersion = (req.user.tokenVersion || 0) + 1;
  await req.user.save();
  res.json({ message: 'Signed out.' });
}

export async function uploadAvatar(req, res) {
  if (!req.file?.path || !req.file?.filename) {
    return res.status(400).json({ message: 'Choose an image to upload.' });
  }

  const oldPublicId = req.user.profileImagePublicId;
  req.user.profileImage = req.file.path;
  req.user.profileImagePublicId = req.file.filename;
  try {
    await req.user.save();
  } catch (error) {
    try {
      await cloudinary.uploader.destroy(req.file.filename, { resource_type: 'image' });
    } catch (cleanupError) {
      console.error('Unable to remove an avatar after its profile save failed:', cleanupError.message);
    }
    throw error;
  }

  if (oldPublicId && oldPublicId !== req.file.filename) {
    try {
      await cloudinary.uploader.destroy(oldPublicId, { resource_type: 'image' });
    } catch (error) {
      console.error('Unable to delete replaced profile image:', error.message);
    }
  }
  res.json({ user: req.user.toPublicJSON() });
}
