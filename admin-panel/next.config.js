/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  env: {
    BACKEND_URL: process.env.BACKEND_URL || 'http://localhost:5000',
  },
  async redirects() {
    return [
      {
        source: '/',
        destination: '/admin',
        permanent: false,
      },
    ]
  },
  images: {
    domains: ['res.cloudinary.com'],
  },
  experimental: {
    serverComponentsExternalPackages: ['firebase-admin']
  },
  webpack: (config) => {
    config.externals.push({
      'utf-8-validate': 'commonjs utf-8-validate',
      'bufferutil': 'commonjs bufferutil',
    })
    return config
  },
}

module.exports = nextConfig