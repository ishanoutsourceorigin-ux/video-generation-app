const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

class CloudinaryService {
  
  /**
   * Upload image to Cloudinary
   * @param {Buffer} fileBuffer - Image buffer
   * @param {string} folder - Cloudinary folder
   * @param {string} publicId - Optional public ID
   * @returns {Promise<string>} Cloudinary URL
   */
  static async uploadImage(fileBuffer, folder = 'profile_images', publicId = null) {
    try {
      return new Promise((resolve, reject) => {
        const uploadOptions = {
          folder: folder,
          resource_type: 'image',
          format: 'jpg',
          quality: 'auto:good',
          transformation: [
            { width: 400, height: 400, crop: 'fill', gravity: 'face' },
            { quality: 'auto:good' }
          ],
        };

        if (publicId) {
          uploadOptions.public_id = publicId;
        }

        cloudinary.uploader.upload_stream(
          uploadOptions,
          (error, result) => {
            if (error) {
              console.error('Cloudinary upload error:', error);
              reject(error);
            } else {
              resolve(result.secure_url);
            }
          }
        ).end(fileBuffer);
      });
    } catch (error) {
      console.error('Upload image error:', error);
      throw error;
    }
  }

  /**
   * Delete image from Cloudinary
   * @param {string} publicId - Cloudinary public ID
   * @returns {Promise<object>} Deletion result
   */
  static async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result;
    } catch (error) {
      console.error('Delete image error:', error);
      throw error;
    }
  }

  /**
   * Get Cloudinary configuration status
   * @returns {object} Configuration status
   */
  static getStatus() {
    const config = cloudinary.config();
    return {
      configured: !!(config.cloud_name && config.api_key && config.api_secret),
      cloud_name: config.cloud_name,
      api_key: config.api_key ? `${config.api_key.substring(0, 6)}...` : null,
    };
  }

  /**
   * Generate upload signature for frontend uploads
   * @param {object} params - Upload parameters
   * @returns {object} Signature data
   */
  static generateSignature(params = {}) {
    const timestamp = Math.round(Date.now() / 1000);
    const paramsToSign = {
      timestamp,
      folder: 'profile_images',
      ...params,
    };

    const signature = cloudinary.utils.api_sign_request(paramsToSign, process.env.CLOUDINARY_API_SECRET);
    
    return {
      signature,
      timestamp,
      api_key: process.env.CLOUDINARY_API_KEY,
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      ...paramsToSign,
    };
  }
}

module.exports = CloudinaryService;