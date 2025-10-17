"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Shield, Eye, EyeOff, AlertCircle } from "lucide-react";
import Link from "next/link";
import toast from "react-hot-toast";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../../lib/firebase";

export default function AdminLoginPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    email: "ishanoutsourceorigin@gmail.com",
    password: "",
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // Check if admin is already logged in
    const token = localStorage.getItem("adminToken");
    const adminData = localStorage.getItem("adminData");

    if (token && adminData) {
      router.push("/admin/dashboard");
    }
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Clear any existing tokens to prevent conflicts
      localStorage.removeItem("adminToken");
      localStorage.removeItem("adminData");

      // Step 1: Sign in with Firebase
      const userCredential = await signInWithEmailAndPassword(
        auth,
        formData.email,
        formData.password
      );

      const user = userCredential.user;

      // Check if this is the authorized admin email
      if (user.email !== "ishanoutsourceorigin@gmail.com") {
        await auth.signOut(); // Sign out unauthorized user
        toast.error("Unauthorized: Admin access required");
        return;
      }

      // Step 2: Get Firebase ID token
      const idToken = await user.getIdToken();

      // Step 3: Exchange Firebase token for backend JWT
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/firebase-login`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${idToken}`,
          },
          body: JSON.stringify({
            email: user.email,
            uid: user.uid,
          }),
        }
      );

      const data = await response.json();

      if (response.ok && data.success) {
        // Store admin token and data
        localStorage.setItem("adminToken", data.token);
        localStorage.setItem("adminData", JSON.stringify(data.admin));

        toast.success("Admin login successful!");
        router.push("/admin/dashboard");
      } else {
        await auth.signOut(); // Sign out on backend error
        toast.error(data.message || "Authentication failed");
      }
    } catch (error: any) {
      console.error("Login error:", error);
      toast.error("Network error. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center px-6">
      <div className="max-w-md w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mx-auto mb-4">
            <Shield className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Admin Portal</h1>
          <p className="text-gray-300">
            Sign in to access the CloneX admin dashboard
          </p>
        </div>

        {/* Login Form */}
        <div className="glass-effect rounded-2xl p-8">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label
                htmlFor="email"
                className="block text-sm font-medium text-gray-300 mb-2"
              >
                Admin Email
              </label>
              <input
                type="email"
                id="email"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
                className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                placeholder="Enter admin email"
                required
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-300 mb-2"
              >
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  id="password"
                  value={formData.password}
                  onChange={(e) =>
                    setFormData({ ...formData, password: e.target.value })
                  }
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent pr-12"
                  placeholder="Enter admin password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  {showPassword ? (
                    <EyeOff className="w-5 h-5" />
                  ) : (
                    <Eye className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 rounded-lg font-semibold hover:from-purple-600 hover:to-pink-600 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <div className="spinner mr-2"></div>
                  Signing in...
                </div>
              ) : (
                "Sign In as Admin"
              )}
            </button>
          </form>

          {/* Privacy Policy Link */}
          <div className="mt-6 text-center">
            <Link
              href="/privacy"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-gray-400 hover:text-white transition-colors underline"
            >
              Privacy Policy
            </Link>
          </div>

          {/* Admin Info
          <div className="mt-6 p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
            <div className="flex items-start">
              <AlertCircle className="w-5 h-5 text-amber-400 mr-2 mt-0.5 flex-shrink-0" />
              <div className="text-sm">
                <p className="text-amber-300 font-medium mb-1">
                  Default Admin Credentials
                </p>
                <p className="text-amber-200">
                  <strong>Email:</strong> ishanoutsourceorigin@gmail.com
                  <br />
                  <strong>Password:</strong> admin123
                </p>
                <p className="text-amber-200 text-xs mt-2 opacity-75">
                  Change these credentials in production by setting ADMIN_EMAIL and ADMIN_PASSWORD environment variables.
                </p>
              </div>
            </div>
          </div> */}
        </div>

        {/* Back to Site */}
        {/* <div className="text-center mt-6">
          <button
            onClick={() => router.push("/")}
            className="text-gray-400 hover:text-white transition-colors"
          >
            ← Back to main site
          </button>
        </div> */}
      </div>
    </div>
  );
}
