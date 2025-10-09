"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  Shield,
  Users,
  Video,
  DollarSign,
  TrendingUp,
  Settings,
  LogOut,
  Search,
  Filter,
  Download,
  Eye,
  EyeOff,
  Trash2,
  Edit3,
  CreditCard,
  Activity,
  Calendar,
  BarChart3,
  User,
  Mail,
  AlertCircle,
  Save,
  Lock,
  Key,
  RefreshCw,
} from "lucide-react";
import toast from "react-hot-toast";

interface AdminStats {
  totalUsers: number;
  totalProjects: number;
  totalRevenue: number;
  recentTransactions: number;
  newUsers: number;
  projectsByStatus: {
    [key: string]: number;
  };
}

interface User {
  id: number;
  name: string;
  email: string;
  credits: number;
  plan: string;
  totalProjects: number;
  totalSpent: number;
  createdAt: string;
}

interface Project {
  id: string;
  title: string;
  status: string;
  processingStep: string;
  duration: string;
  createdAt: string;
  user: {
    id: number;
    name: string;
    email: string;
  };
  videoUrl: string;
  thumbnailUrl: string;
}

interface Transaction {
  id: number;
  planType: string;
  amount: number;
  currency: string;
  creditsPurchased: number;
  status: string;
  stripeSessionId: string;
  createdAt: string;
  user: {
    id: number;
    name: string;
    email: string;
  };
}

type ActiveTab =
  | "overview"
  | "users"
  | "projects"
  | "transactions"
  | "settings";

export default function AdminDashboard() {
  const router = useRouter();
  const [admin, setAdmin] = useState<any>(null);
  const [activeTab, setActiveTab] = useState<ActiveTab>("overview");
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  // Settings form states
  const [profileData, setProfileData] = useState({
    fullName: "",
  });
  const [passwordData, setPasswordData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false,
  });

  // System health states
  const [systemHealth, setSystemHealth] = useState({
    api: { status: "checking", message: "Checking..." },
    database: { status: "checking", message: "Checking..." },
    elevenLabs: { status: "checking", message: "Checking..." },
    runway: { status: "checking", message: "Checking..." },
    didApi: { status: "checking", message: "Checking..." },
  });

  useEffect(() => {
    // Check admin authentication
    const token = localStorage.getItem("adminToken");
    const adminData = localStorage.getItem("adminData");

    if (!token || !adminData) {
      router.push("/admin");
      return;
    }

    const parsedAdminData = JSON.parse(adminData);
    setAdmin(parsedAdminData);

    // Initialize profile data - check Firebase first if it's a Firebase admin
    const initializeProfile = async () => {
      let displayName = parsedAdminData.name || parsedAdminData.fullName || "";

      // If Firebase admin, get current display name from Firebase
      if (parsedAdminData.uid) {
        try {
          const { auth } = await import("../../../lib/firebase");
          const user = auth.currentUser;
          if (user && user.displayName) {
            displayName = user.displayName;
            console.log("📱 Loaded Firebase display name:", displayName);
          }
        } catch (firebaseError) {
          console.log(
            "Could not load Firebase user profile, using stored data"
          );
        }
      }

      setProfileData({
        fullName: displayName,
      });
    };

    initializeProfile();
    fetchDashboardData();
    checkSystemHealth();
  }, [router]);

  const checkSystemHealth = async () => {
    const token = localStorage.getItem("adminToken");

    // Check API status
    try {
      const apiResponse = await fetch(
        `${process.env.BACKEND_URL || "http://localhost:5000"}/api/health`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (apiResponse.ok) {
        setSystemHealth((prev) => ({
          ...prev,
          api: { status: "online", message: "Online" },
        }));
      } else {
        setSystemHealth((prev) => ({
          ...prev,
          api: { status: "error", message: `Error ${apiResponse.status}` },
        }));
      }
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        api: { status: "offline", message: "Connection failed" },
      }));
    }

    // Check Database status
    try {
      const dbResponse = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/health/database`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const dbData = await dbResponse.json();

      if (dbResponse.ok && dbData.success) {
        setSystemHealth((prev) => ({
          ...prev,
          database: { status: "connected", message: "Connected" },
        }));
      } else {
        setSystemHealth((prev) => ({
          ...prev,
          database: {
            status: "error",
            message: dbData.message || "Database error",
          },
        }));
      }
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        database: { status: "disconnected", message: "Connection failed" },
      }));
    }

    // Check ElevenLabs API
    try {
      const elevenResponse = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/health/elevenlabs`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const elevenData = await elevenResponse.json();

      if (elevenResponse.ok && elevenData.success) {
        setSystemHealth((prev) => ({
          ...prev,
          elevenLabs: {
            status: "active",
            message: elevenData.message || "Active",
          },
        }));
      } else {
        setSystemHealth((prev) => ({
          ...prev,
          elevenLabs: {
            status: "error",
            message: elevenData.error || "API key invalid",
          },
        }));
      }
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        elevenLabs: { status: "offline", message: "Service unavailable" },
      }));
    }

    // Check Runway API
    try {
      const runwayResponse = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/health/runway`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const runwayData = await runwayResponse.json();

      if (runwayResponse.ok && runwayData.success) {
        setSystemHealth((prev) => ({
          ...prev,
          runway: { status: "active", message: runwayData.message || "Active" },
        }));
      } else {
        setSystemHealth((prev) => ({
          ...prev,
          runway: {
            status: "error",
            message: runwayData.error || "API key invalid",
          },
        }));
      }
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        runway: { status: "offline", message: "Service unavailable" },
      }));
    }

    // Check D-ID API
    try {
      const didResponse = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/health/did`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const didData = await didResponse.json();

      if (didResponse.ok && didData.success) {
        setSystemHealth((prev) => ({
          ...prev,
          didApi: { status: "active", message: didData.message || "Active" },
        }));
      } else {
        setSystemHealth((prev) => ({
          ...prev,
          didApi: {
            status: "error",
            message: didData.error || "API key invalid",
          },
        }));
      }
    } catch (error) {
      setSystemHealth((prev) => ({
        ...prev,
        didApi: { status: "offline", message: "Service unavailable" },
      }));
    }
  };

  const getHealthStatusColor = (status: string) => {
    switch (status) {
      case "online":
      case "connected":
      case "active":
        return "text-green-400";
      case "checking":
        return "text-yellow-400";
      case "error":
      case "offline":
      case "disconnected":
        return "text-red-400";
      default:
        return "text-gray-400";
    }
  };

  const getHealthDotColor = (status: string) => {
    switch (status) {
      case "online":
      case "connected":
      case "active":
        return "bg-green-400";
      case "checking":
        return "bg-yellow-400 animate-pulse";
      case "error":
      case "offline":
      case "disconnected":
        return "bg-red-400";
      default:
        return "bg-gray-400";
    }
  };

  const fetchDashboardData = async () => {
    try {
      await Promise.all([
        fetchStats(),
        fetchUsers(1, "", 20), // Increased limit for overview
        fetchProjects(1, "", "", 20), // Increased limit for overview
        fetchTransactions(1, "", "", 20), // Increased limit for overview
      ]);
    } catch (error) {
      console.error("Error fetching dashboard data:", error);
      toast.error("Failed to load dashboard data");
    } finally {
      setIsLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${process.env.BACKEND_URL || "http://localhost:5000"}/api/admin/stats`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.status === 401) {
        // Token is invalid, redirect to login
        localStorage.removeItem("adminToken");
        localStorage.removeItem("adminData");
        router.push("/admin");
        return;
      }

      if (response.ok) {
        const data = await response.json();
        setStats(data.stats);
      }
    } catch (error) {
      console.error("Error fetching stats:", error);
    }
  };

  const fetchUsers = async (page = 1, search = "", limit = 10) => {
    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/users?page=${page}&limit=${limit}&search=${search}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setUsers(data.users);
        setTotalPages(data.pagination.pages);
      }
    } catch (error) {
      console.error("Error fetching users:", error);
    }
  };

  const fetchProjects = async (
    page = 1,
    status = "",
    search = "",
    limit = 10
  ) => {
    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/projects?page=${page}&limit=${limit}&status=${status}&search=${search}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setProjects(data.projects);
        setTotalPages(data.pagination.pages);
      }
    } catch (error) {
      console.error("Error fetching projects:", error);
    }
  };

  const fetchTransactions = async (
    page = 1,
    status = "",
    search = "",
    limit = 10
  ) => {
    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/transactions?page=${page}&limit=${limit}&status=${status}&search=${search}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setTransactions(data.transactions);
        setTotalPages(data.pagination.pages);
      }
    } catch (error) {
      console.error("Error fetching transactions:", error);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("adminToken");
    localStorage.removeItem("adminData");
    router.push("/admin");
    toast.success("Logged out successfully");
  };

  const updateUserCredits = async (userId: number, newCredits: number) => {
    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/users/${userId}/credits`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ credits: newCredits }),
        }
      );

      if (response.ok) {
        toast.success("User credits updated successfully");
        fetchUsers(currentPage, searchTerm, 10);
      } else {
        toast.error("Failed to update user credits");
      }
    } catch (error) {
      console.error("Error updating user credits:", error);
      toast.error("Failed to update user credits");
    }
  };

  const deleteUser = async (userId: number) => {
    if (
      !confirm(
        "Are you sure you want to delete this user? This will also delete all their projects and transactions."
      )
    ) {
      return;
    }

    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/users/${userId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        toast.success("User deleted successfully");
        fetchUsers(currentPage, searchTerm, 10);
        fetchStats(); // Refresh stats
      } else {
        toast.error("Failed to delete user");
      }
    } catch (error) {
      console.error("Error deleting user:", error);
      toast.error("Failed to delete user");
    }
  };

  const deleteProject = async (projectId: string) => {
    if (!confirm("Are you sure you want to delete this project?")) {
      return;
    }

    try {
      const token = localStorage.getItem("adminToken");
      const response = await fetch(
        `${
          process.env.BACKEND_URL || "http://localhost:5000"
        }/api/admin/projects/${projectId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (response.ok) {
        toast.success("Project deleted successfully");
        fetchProjects(currentPage, statusFilter, searchTerm, 10);
        fetchStats(); // Refresh stats
      } else {
        toast.error("Failed to delete project");
      }
    } catch (error) {
      console.error("Error deleting project:", error);
      toast.error("Failed to delete project");
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const formatDuration = (duration: string) => {
    if (!duration || duration === "N/A") return "N/A";

    // Remove 's' if present and convert to number
    const numericValue = duration.replace(/s$/, "");
    const seconds = parseFloat(numericValue);

    if (isNaN(seconds)) return duration;

    // Round to 1 decimal place and add "sec"
    return `${seconds.toFixed(1)} sec`;
  };

  // Form handlers for settings
  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!profileData.fullName || profileData.fullName.trim().length === 0) {
      toast.error("Name is required");
      return;
    }

    try {
      // Check if this is a Firebase admin user
      const adminData = localStorage.getItem("adminData");
      const parsedAdminData = adminData ? JSON.parse(adminData) : null;
      const isFirebaseAdmin = parsedAdminData?.uid;

      // Firebase Admin Only - Update profile in Firebase and backend
      const { updateProfile } = await import("firebase/auth");
      const { auth } = await import("../../../lib/firebase");

      try {
        const user = auth.currentUser;
        if (!user) {
          toast.error("Not authenticated with Firebase");
          return;
        }

        // Update display name in Firebase Authentication
        await updateProfile(user, {
          displayName: profileData.fullName.trim(),
        });

        console.log("✅ Firebase profile updated on frontend");

        // Also update via backend API for consistency
        const token = localStorage.getItem("adminToken");
        const response = await fetch(
          `${
            process.env.BACKEND_URL || "http://localhost:5000"
          }/api/admin/profile`,
          {
            method: "PUT",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
              name: profileData.fullName.trim(),
            }),
          }
        );

        const data = await response.json();

        if (response.ok && data.success) {
          // Update local storage with new admin data
          const updatedAdminData = {
            ...admin,
            name: profileData.fullName.trim(),
            displayName: profileData.fullName.trim(),
          };
          localStorage.setItem("adminData", JSON.stringify(updatedAdminData));
          setAdmin(updatedAdminData);

          toast.success("Firebase profile updated successfully!");
        } else {
          toast.error(data.message || "Backend update failed");
        }
      } catch (firebaseError: any) {
        console.error("Firebase profile update error:", firebaseError);
        toast.error(
          "Failed to update Firebase profile: " + firebaseError.message
        );
        return;
      }
    } catch (error) {
      console.error("Profile update error:", error);
      toast.error("Failed to update profile");
    }
  };

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();

    if (passwordData.newPassword !== passwordData.confirmPassword) {
      toast.error("New passwords don't match");
      return;
    }

    if (passwordData.newPassword.length < 6) {
      toast.error("Password must be at least 6 characters long");
      return;
    }

    if (!passwordData.currentPassword) {
      toast.error("Current password is required");
      return;
    }

    try {
      // Check if this is a Firebase admin user
      const adminData = localStorage.getItem("adminData");
      const parsedAdminData = adminData ? JSON.parse(adminData) : null;
      const isFirebaseAdmin = parsedAdminData?.uid;

      // Firebase Admin Only - Use Firebase Authentication for password update
      const {
        updatePassword,
        EmailAuthProvider,
        reauthenticateWithCredential,
      } = await import("firebase/auth");
      const { auth } = await import("../../../lib/firebase");

      try {
        const user = auth.currentUser;
        if (!user) {
          toast.error("Not authenticated with Firebase");
          return;
        }

        // Re-authenticate user with current password
        const credential = EmailAuthProvider.credential(
          user.email!,
          passwordData.currentPassword
        );
        await reauthenticateWithCredential(user, credential);

        // Update password in Firebase
        await updatePassword(user, passwordData.newPassword);

        toast.success("Firebase password updated successfully!");
        setPasswordData({
          currentPassword: "",
          newPassword: "",
          confirmPassword: "",
        });
      } catch (firebaseError: any) {
        console.error("Firebase password update error:", firebaseError);

        if (firebaseError.code === "auth/wrong-password") {
          toast.error("Current password is incorrect");
        } else if (firebaseError.code === "auth/weak-password") {
          toast.error("New password is too weak");
        } else if (firebaseError.code === "auth/requires-recent-login") {
          toast.error(
            "Please log out and log in again before changing password"
          );
        } else {
          toast.error(
            "Failed to update Firebase password: " + firebaseError.message
          );
        }
        return;
      }
    } catch (error: any) {
      console.error("Password update error:", error);
      toast.error(
        "Failed to update password: " + (error.message || "Unknown error")
      );
    }
  };

  const togglePasswordVisibility = (field: "current" | "new" | "confirm") => {
    setShowPasswords((prev) => ({
      ...prev,
      [field]: !prev[field],
    }));
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "text-green-400 bg-green-400/10";
      case "processing":
        return "text-yellow-400 bg-yellow-400/10";
      case "pending":
        return "text-blue-400 bg-blue-400/10";
      case "failed":
        return "text-red-400 bg-red-400/10";
      default:
        return "text-gray-400 bg-gray-400/10";
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center">
        <div className="glass-effect rounded-xl p-8 text-center">
          <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl flex items-center justify-center mx-auto mb-4">
            <Shield className="w-6 h-6 text-white" />
          </div>
          <div className="text-white text-lg mb-2">
            Loading Admin Dashboard...
          </div>
          <div className="text-gray-400 text-sm">
            Fetching comprehensive data...
          </div>
          <div className="mt-4 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500"></div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Header */}
      <header className="border-b border-white/10 px-6 py-4 glass-effect">
        <div className="flex items-center justify-between max-w-7xl mx-auto">
          <div className="flex items-center space-x-4">
            <div className="w-10 h-10 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">CloneX Admin</h1>
              <p className="text-gray-400 text-sm">Administrator Dashboard</p>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-gray-300">Welcome, {admin?.email}</span>
            <button
              onClick={handleLogout}
              className="flex items-center text-gray-400 hover:text-white transition-colors"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Logout
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Navigation Tabs */}
        <div className="mb-8">
          <div className="flex space-x-1 bg-white/5 rounded-lg p-1">
            {[
              { id: "overview", label: "Overview", icon: BarChart3 },
              { id: "users", label: "Users", icon: Users },
              { id: "projects", label: "Projects", icon: Video },
              { id: "transactions", label: "Payments", icon: CreditCard },
              { id: "settings", label: "Settings", icon: Settings },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as ActiveTab)}
                className={`flex items-center px-4 py-2 rounded-md font-medium transition-all ${
                  activeTab === tab.id
                    ? "bg-gradient-to-r from-purple-500 to-pink-500 text-white"
                    : "text-gray-300 hover:text-white hover:bg-white/10"
                }`}
              >
                <tab.icon className="w-4 h-4 mr-2" />
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Overview Tab */}
        {activeTab === "overview" && stats && (
          <div className="space-y-8">
            {/* Main Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="glass-effect rounded-xl p-6 border border-blue-500/20">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-300 text-sm">Total Users</p>
                    <p className="text-3xl font-bold text-white">
                      {stats.totalUsers}
                    </p>
                    <p className="text-green-400 text-sm mt-1">
                      +{stats.newUsers} this month
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500/10 rounded-xl flex items-center justify-center">
                    <Users className="w-7 h-7 text-blue-400" />
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-white/10">
                  <div className="flex items-center text-sm text-gray-300">
                    <TrendingUp className="w-4 h-4 mr-1 text-green-400" />
                    Growth rate:{" "}
                    {stats.totalUsers > 0
                      ? ((stats.newUsers / stats.totalUsers) * 100).toFixed(1)
                      : 0}
                    %
                  </div>
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6 border border-purple-500/20">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-300 text-sm">Total Projects</p>
                    <p className="text-3xl font-bold text-white">
                      {stats.totalProjects}
                    </p>
                    <p className="text-purple-400 text-sm mt-1">
                      {stats.projectsByStatus.completed || 0} completed
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500/10 rounded-xl flex items-center justify-center">
                    <Video className="w-7 h-7 text-purple-400" />
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-white/10">
                  <div className="flex items-center text-sm text-gray-300">
                    <Activity className="w-4 h-4 mr-1 text-yellow-400" />
                    Success rate:{" "}
                    {stats.totalProjects > 0
                      ? (
                          ((stats.projectsByStatus.completed || 0) /
                            stats.totalProjects) *
                          100
                        ).toFixed(1)
                      : 0}
                    %
                  </div>
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6 border border-green-500/20">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-300 text-sm">Total Revenue</p>
                    <p className="text-3xl font-bold text-white">
                      ${stats.totalRevenue.toFixed(2)}
                    </p>
                    <p className="text-green-400 text-sm mt-1">
                      {stats.recentTransactions} recent transactions
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-green-500/10 rounded-xl flex items-center justify-center">
                    <DollarSign className="w-7 h-7 text-green-400" />
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-white/10">
                  <div className="flex items-center text-sm text-gray-300">
                    <CreditCard className="w-4 h-4 mr-1 text-green-400" />
                    Avg per user: $
                    {stats.totalUsers > 0
                      ? (stats.totalRevenue / stats.totalUsers).toFixed(2)
                      : "0.00"}
                  </div>
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6 border border-yellow-500/20">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-300 text-sm">Active Processing</p>
                    <p className="text-3xl font-bold text-white">
                      {stats.projectsByStatus.processing || 0}
                    </p>
                    <p className="text-yellow-400 text-sm mt-1">
                      Currently generating
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-yellow-500/10 rounded-xl flex items-center justify-center">
                    <Activity className="w-7 h-7 text-yellow-400" />
                  </div>
                </div>
                <div className="mt-4 pt-4 border-t border-white/10">
                  <div className="flex items-center text-sm text-gray-300">
                    <Calendar className="w-4 h-4 mr-1 text-yellow-400" />
                    Queue status:{" "}
                    {(stats.projectsByStatus.pending || 0) +
                      (stats.projectsByStatus.processing || 0)}{" "}
                    pending
                  </div>
                </div>
              </div>
            </div>

            {/* Additional Stats Row */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="glass-effect rounded-xl p-6">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-white">
                    System Health
                  </h4>
                  <button
                    onClick={checkSystemHealth}
                    className="text-purple-400 hover:text-purple-300 text-sm flex items-center"
                  >
                    <RefreshCw className="w-4 h-4 mr-1" />
                    Refresh
                  </button>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">API Status</span>
                    <span
                      className={`flex items-center ${getHealthStatusColor(
                        systemHealth.api.status
                      )}`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full mr-2 ${getHealthDotColor(
                          systemHealth.api.status
                        )}`}
                      ></div>
                      {systemHealth.api.message}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Database</span>
                    <span
                      className={`flex items-center ${getHealthStatusColor(
                        systemHealth.database.status
                      )}`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full mr-2 ${getHealthDotColor(
                          systemHealth.database.status
                        )}`}
                      ></div>
                      {systemHealth.database.message}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">ElevenLabs API</span>
                    <span
                      className={`flex items-center ${getHealthStatusColor(
                        systemHealth.elevenLabs.status
                      )}`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full mr-2 ${getHealthDotColor(
                          systemHealth.elevenLabs.status
                        )}`}
                      ></div>
                      {systemHealth.elevenLabs.message}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Runway API</span>
                    <span
                      className={`flex items-center ${getHealthStatusColor(
                        systemHealth.runway.status
                      )}`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full mr-2 ${getHealthDotColor(
                          systemHealth.runway.status
                        )}`}
                      ></div>
                      {systemHealth.runway.message}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">D-ID API</span>
                    <span
                      className={`flex items-center ${getHealthStatusColor(
                        systemHealth.didApi.status
                      )}`}
                    >
                      <div
                        className={`w-2 h-2 rounded-full mr-2 ${getHealthDotColor(
                          systemHealth.didApi.status
                        )}`}
                      ></div>
                      {systemHealth.didApi.message}
                    </span>
                  </div>
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6">
                <h4 className="text-lg font-semibold text-white mb-4">
                  Project Analytics
                </h4>
                <div className="space-y-3">
                  {Object.entries(stats.projectsByStatus).map(
                    ([status, count]) => (
                      <div
                        key={status}
                        className="flex justify-between items-center"
                      >
                        <div className="flex items-center">
                          <div
                            className={`w-3 h-3 rounded-full mr-2 ${
                              status === "completed"
                                ? "bg-green-400"
                                : status === "processing"
                                ? "bg-yellow-400"
                                : status === "pending"
                                ? "bg-blue-400"
                                : status === "failed"
                                ? "bg-red-400"
                                : "bg-gray-400"
                            }`}
                          ></div>
                          <span className="text-gray-300 capitalize">
                            {status}
                          </span>
                        </div>
                        <span className="text-white font-medium">{count}</span>
                      </div>
                    )
                  )}
                </div>
              </div>

              <div className="glass-effect rounded-xl p-6">
                <h4 className="text-lg font-semibold text-white mb-4">
                  Quick Actions
                </h4>
                <div className="space-y-3">
                  <button
                    onClick={() => setActiveTab("users")}
                    className="w-full text-left p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors text-gray-300 hover:text-white"
                  >
                    <Users className="w-4 h-4 inline mr-2" />
                    Manage Users
                  </button>
                  <button
                    onClick={() => setActiveTab("projects")}
                    className="w-full text-left p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors text-gray-300 hover:text-white"
                  >
                    <Video className="w-4 h-4 inline mr-2" />
                    View Projects
                  </button>
                  <button
                    onClick={() => setActiveTab("transactions")}
                    className="w-full text-left p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors text-gray-300 hover:text-white"
                  >
                    <CreditCard className="w-4 h-4 inline mr-2" />
                    Transaction History
                  </button>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Recent Users */}
              <div className="glass-effect rounded-xl p-6">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-white">
                    Recent Users
                  </h4>
                  <button
                    onClick={() => setActiveTab("users")}
                    className="text-purple-400 hover:text-purple-300 text-sm"
                  >
                    View All →
                  </button>
                </div>
                <div className="space-y-3">
                  {users.slice(0, 5).map((user) => (
                    <div
                      key={user.id}
                      className="flex items-center justify-between p-3 bg-white/5 rounded-lg"
                    >
                      <div>
                        <p className="text-white font-medium">{user.name}</p>
                        <p className="text-gray-400 text-sm">{user.email}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-white text-sm">
                          {user.credits} credits
                        </p>
                        <p className="text-gray-400 text-xs">
                          {formatDate(user.createdAt)}
                        </p>
                      </div>
                    </div>
                  ))}
                  {users.length === 0 && (
                    <div className="text-center py-8">
                      <Users className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                      <p className="text-gray-400 mb-2">No users found</p>
                      <p className="text-gray-500 text-sm">
                        Users will appear here once they register
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {/* Recent Projects */}
              <div className="glass-effect rounded-xl p-6">
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-white">
                    Recent Projects
                  </h4>
                  <button
                    onClick={() => setActiveTab("projects")}
                    className="text-purple-400 hover:text-purple-300 text-sm"
                  >
                    View All →
                  </button>
                </div>
                <div className="space-y-3">
                  {projects.slice(0, 5).map((project) => (
                    <div
                      key={project.id}
                      className="flex items-center justify-between p-3 bg-white/5 rounded-lg"
                    >
                      <div>
                        <p className="text-white font-medium">
                          {project.title}
                        </p>
                        <p className="text-gray-400 text-sm">
                          by{" "}
                          {project.user.name ||
                            project.user.email ||
                            project.user.id}
                        </p>
                      </div>
                      <div className="text-right">
                        <span
                          className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
                            project.status
                          )}`}
                        >
                          {project.status}
                        </span>
                        <p className="text-gray-400 text-xs mt-1">
                          {formatDate(project.createdAt)}
                        </p>
                      </div>
                    </div>
                  ))}
                  {projects.length === 0 && (
                    <div className="text-center py-8">
                      <Video className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                      <p className="text-gray-400 mb-2">No projects found</p>
                      <p className="text-gray-500 text-sm">
                        Video projects will appear here once users create them
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Users Tab */}
        {activeTab === "users" && (
          <div className="space-y-6">
            {/* Search and Filter */}
            <div className="flex space-x-4">
              <div className="flex-1 relative">
                <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search users by name or email..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyPress={(e) =>
                    e.key === "Enter" && fetchUsers(1, searchTerm)
                  }
                  className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <button
                onClick={() => fetchUsers(1, searchTerm, 10)}
                className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-medium hover:from-purple-600 hover:to-pink-600 transition-all"
              >
                Search
              </button>
            </div>

            {/* Users Table */}
            <div className="glass-effect rounded-xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-white/5">
                    <tr>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        User
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Credits
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Projects
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Total Spent
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Joined
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user) => (
                      <tr key={user.id} className="border-t border-white/5">
                        <td className="py-4 px-6">
                          <div>
                            <p className="text-white font-medium">
                              {user.name}
                            </p>
                            <p className="text-gray-400 text-sm">
                              {user.email}
                            </p>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex items-center space-x-2">
                            <span className="text-white font-medium">
                              {user.credits}
                            </span>
                            <button
                              onClick={() => {
                                const newCredits = prompt(
                                  `Enter new credits for ${user.name}:`,
                                  user.credits.toString()
                                );
                                if (
                                  newCredits &&
                                  !isNaN(parseInt(newCredits))
                                ) {
                                  updateUserCredits(
                                    user.id,
                                    parseInt(newCredits)
                                  );
                                }
                              }}
                              className="text-purple-400 hover:text-purple-300"
                            >
                              <Edit3 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white">
                            {user.totalProjects}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white">
                            ${user.totalSpent.toFixed(2)}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-gray-300">
                            {formatDate(user.createdAt)}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <button
                            onClick={() => deleteUser(user.id)}
                            className="text-red-400 hover:text-red-300"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Projects Tab */}
        {activeTab === "projects" && (
          <div className="space-y-6">
            {/* Search and Filter */}
            <div className="flex space-x-4">
              <div className="flex-1 relative">
                <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search projects..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyPress={(e) =>
                    e.key === "Enter" &&
                    fetchProjects(1, statusFilter, searchTerm)
                  }
                  className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="bg-white/10 border border-white/20 rounded-lg text-white px-4 py-3 focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                <option value="">All Status</option>
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="completed">Completed</option>
                <option value="failed">Failed</option>
              </select>
              <button
                onClick={() => fetchProjects(1, statusFilter, searchTerm, 10)}
                className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-medium hover:from-purple-600 hover:to-pink-600 transition-all"
              >
                Search
              </button>
            </div>

            {/* Projects Table */}
            <div className="glass-effect rounded-xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-white/5">
                    <tr>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Project
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        User
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Status
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Duration
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Created
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {projects.map((project) => (
                      <tr key={project.id} className="border-t border-white/5">
                        <td className="py-4 px-6">
                          <div>
                            <p className="text-white font-medium">
                              {project.title}
                            </p>
                            <p className="text-gray-400 text-sm">
                              ID: {project.id}
                            </p>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <div>
                            <p className="text-white font-medium">
                              {project.user.name ||
                                project.user.email ||
                                project.user.id}
                            </p>
                            <p className="text-gray-400 text-sm">
                              {project.user.email}
                            </p>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <span
                            className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
                              project.status
                            )}`}
                          >
                            {project.status}
                          </span>
                          {project.processingStep && (
                            <p className="text-gray-400 text-xs mt-1">
                              {project.processingStep}
                            </p>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white">
                            {formatDuration(project.duration)}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-gray-300">
                            {formatDate(project.createdAt)}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex space-x-2">
                            {project.videoUrl && (
                              <button
                                onClick={() => {
                                  let videoUrl = project.videoUrl;

                                  // Handle different URL formats
                                  if (!videoUrl.startsWith("http")) {
                                    // If it's a relative path, prepend backend URL
                                    videoUrl = `${
                                      process.env.BACKEND_URL ||
                                      "http://localhost:5000"
                                    }${
                                      videoUrl.startsWith("/")
                                        ? videoUrl
                                        : "/" + videoUrl
                                    }`;
                                  }

                                  // Validate URL before opening
                                  if (
                                    videoUrl &&
                                    !videoUrl.includes("null") &&
                                    !videoUrl.includes("undefined")
                                  ) {
                                    console.log("Opening video URL:", videoUrl);
                                    window.open(
                                      videoUrl,
                                      "_blank",
                                      "noopener,noreferrer"
                                    );
                                  } else {
                                    toast.error(
                                      "Video not available or still processing"
                                    );
                                  }
                                }}
                                className="text-blue-400 hover:text-blue-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                title={
                                  project.videoUrl
                                    ? "View video"
                                    : "Video not available"
                                }
                                disabled={!project.videoUrl}
                              >
                                <Eye className="w-4 h-4" />
                              </button>
                            )}
                            {!project.videoUrl &&
                              project.status === "completed" && (
                                <span
                                  className="text-gray-500"
                                  title="Video file missing"
                                >
                                  <Eye className="w-4 h-4 opacity-30" />
                                </span>
                              )}
                            {!project.videoUrl &&
                              project.status !== "completed" && (
                                <span
                                  className="text-gray-500"
                                  title="Video not ready"
                                >
                                  <Eye className="w-4 h-4 opacity-30" />
                                </span>
                              )}
                            <button
                              onClick={() => deleteProject(project.id)}
                              className="text-red-400 hover:text-red-300 transition-colors"
                              title="Delete project"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Transactions Tab */}
        {activeTab === "transactions" && (
          <div className="space-y-6">
            {/* Search and Filter */}
            <div className="flex space-x-4">
              <div className="flex-1 relative">
                <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search transactions..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyPress={(e) =>
                    e.key === "Enter" &&
                    fetchTransactions(1, statusFilter, searchTerm)
                  }
                  className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                />
              </div>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="bg-white/10 border border-white/20 rounded-lg text-white px-4 py-3 focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                <option value="">All Status</option>
                <option value="pending">Pending</option>
                <option value="completed">Completed</option>
                <option value="failed">Failed</option>
              </select>
              <button
                onClick={() =>
                  fetchTransactions(1, statusFilter, searchTerm, 10)
                }
                className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-medium hover:from-purple-600 hover:to-pink-600 transition-all"
              >
                Search
              </button>
            </div>

            {/* Transactions Table */}
            <div className="glass-effect rounded-xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-white/5">
                    <tr>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Transaction
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        User
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Plan
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Amount
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Credits
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Status
                      </th>
                      <th className="text-left text-gray-300 font-medium py-4 px-6">
                        Date
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {transactions.map((transaction) => (
                      <tr
                        key={transaction.id}
                        className="border-t border-white/5"
                      >
                        <td className="py-4 px-6">
                          <div>
                            <p className="text-white font-medium">
                              #{transaction.id}
                            </p>
                            <p className="text-gray-400 text-sm">
                              {transaction.stripeSessionId.substring(0, 20)}...
                            </p>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <div>
                            <p className="text-white">
                              {transaction.user.name}
                            </p>
                            <p className="text-gray-400 text-sm">
                              {transaction.user.email}
                            </p>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white capitalize">
                            {transaction.planType} Pack
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white font-medium">
                            ${transaction.amount.toFixed(2)}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-white">
                            {transaction.creditsPurchased}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span
                            className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(
                              transaction.status
                            )}`}
                          >
                            {transaction.status}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="text-gray-300">
                            {formatDate(transaction.createdAt)}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Settings Tab */}
        {activeTab === "settings" && (
          <div className="space-y-8">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Profile Information Card */}
              <div className="glass-effect rounded-xl p-6 h-fit">
                <div className="flex items-center mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-500 rounded-xl flex items-center justify-center mr-4 shadow-lg">
                    <User className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-white mb-1">
                      Profile Information
                    </h3>
                    <p className="text-gray-400 text-sm">
                      Manage your account details
                    </p>
                  </div>
                </div>

                <form onSubmit={handleProfileUpdate} className="space-y-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      <Mail className="w-4 h-4 inline mr-2" />
                      Email Address
                    </label>
                    <div className="relative">
                      <input
                        type="email"
                        value={admin?.email || ""}
                        disabled
                        className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-400 disabled:opacity-60 disabled:cursor-not-allowed transition-all duration-200"
                      />
                      <div className="absolute inset-y-0 right-0 flex items-center pr-3">
                        <div className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></div>
                      </div>
                    </div>
                    <p className="text-xs text-yellow-400 mt-2 flex items-center">
                      <AlertCircle className="w-3 h-3 mr-1" />
                      Email cannot be changed for security reasons
                    </p>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      <User className="w-4 h-4 inline mr-2" />
                      Full Name
                    </label>
                    <input
                      type="text"
                      value={profileData.fullName}
                      onChange={(e) =>
                        setProfileData({
                          ...profileData,
                          fullName: e.target.value,
                        })
                      }
                      placeholder={admin?.name || "Enter your full name"}
                      className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-400 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:bg-white/10 transition-all duration-200"
                      required
                    />
                  </div>

                  <div className="pt-6">
                    <button
                      type="submit"
                      className="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 px-6 rounded-lg hover:from-purple-600 hover:to-pink-600 hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-200 font-medium flex items-center justify-center group"
                    >
                      <Save className="w-4 h-4 mr-2 group-hover:scale-110 transition-transform duration-200" />
                      Update Profile
                    </button>
                  </div>
                </form>
              </div>

              {/* Change Password Card */}
              <div className="glass-effect rounded-xl p-6 h-fit">
                <div className="flex items-center mb-6">
                  <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-purple-500 rounded-xl flex items-center justify-center mr-4 shadow-lg">
                    <Shield className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-white mb-1">
                      Change Password
                    </h3>
                    <p className="text-gray-400 text-sm">
                      Update your password to keep your account secure
                    </p>
                  </div>
                </div>

                <form onSubmit={handlePasswordChange} className="space-y-5">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      <Lock className="w-4 h-4 inline mr-2" />
                      Current Password
                    </label>
                    <div className="relative">
                      <input
                        type={showPasswords.current ? "text" : "password"}
                        value={passwordData.currentPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            currentPassword: e.target.value,
                          })
                        }
                        placeholder="Enter current password"
                        className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-400 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:bg-white/10 transition-all duration-200"
                        required
                      />
                      <button
                        type="button"
                        onClick={() => togglePasswordVisibility("current")}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-white transition-colors duration-200"
                      >
                        {showPasswords.current ? (
                          <EyeOff className="w-4 h-4" />
                        ) : (
                          <Eye className="w-4 h-4" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      <Key className="w-4 h-4 inline mr-2" />
                      New Password
                    </label>
                    <div className="relative">
                      <input
                        type={showPasswords.new ? "text" : "password"}
                        value={passwordData.newPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            newPassword: e.target.value,
                          })
                        }
                        placeholder="Enter new password"
                        className="w-full px-4 py-3 pr-12 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-400 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:bg-white/10 transition-all duration-200"
                        required
                        minLength={6}
                      />
                      <button
                        type="button"
                        onClick={() => togglePasswordVisibility("new")}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-white transition-colors duration-200"
                      >
                        {showPasswords.new ? (
                          <EyeOff className="w-4 h-4" />
                        ) : (
                          <Eye className="w-4 h-4" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      <Lock className="w-4 h-4 inline mr-2" />
                      Confirm New Password
                    </label>
                    <div className="relative">
                      <input
                        type={showPasswords.confirm ? "text" : "password"}
                        value={passwordData.confirmPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            confirmPassword: e.target.value,
                          })
                        }
                        placeholder="Confirm new password"
                        className="w-full px-4 py-3 pr-12 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-400 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:bg-white/10 transition-all duration-200"
                        required
                        minLength={6}
                      />
                      <button
                        type="button"
                        onClick={() => togglePasswordVisibility("confirm")}
                        className="absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400 hover:text-white transition-colors duration-200"
                      >
                        {showPasswords.confirm ? (
                          <EyeOff className="w-4 h-4" />
                        ) : (
                          <Eye className="w-4 h-4" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div className="pt-6">
                    <button
                      type="submit"
                      className="w-full bg-gradient-to-r from-purple-500 to-pink-500 text-white py-3 px-6 rounded-lg hover:from-purple-600 hover:to-pink-600 hover:shadow-lg hover:shadow-purple-500/25 transition-all duration-200 font-medium flex items-center justify-center group"
                    >
                      <Shield className="w-4 h-4 mr-2 group-hover:scale-110 transition-transform duration-200" />
                      Update Password
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}

        {/* Pagination */}
        {(activeTab === "users" ||
          activeTab === "projects" ||
          activeTab === "transactions") &&
          totalPages > 1 && (
            <div className="flex justify-center items-center space-x-2 mt-8">
              {/* Previous Button */}
              <button
                onClick={() => {
                  if (currentPage > 1) {
                    const newPage = currentPage - 1;
                    setCurrentPage(newPage);
                    if (activeTab === "users")
                      fetchUsers(newPage, searchTerm, 10);
                    else if (activeTab === "projects")
                      fetchProjects(newPage, statusFilter, searchTerm, 10);
                    else if (activeTab === "transactions")
                      fetchTransactions(newPage, statusFilter, searchTerm, 10);
                  }
                }}
                disabled={currentPage === 1}
                className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 flex items-center ${
                  currentPage === 1
                    ? "bg-gray-700/50 text-gray-500 cursor-not-allowed"
                    : "bg-white/10 text-gray-300 hover:text-white hover:bg-white/20 hover:shadow-lg"
                }`}
              >
                <svg
                  className="w-4 h-4 mr-1"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 19l-7-7 7-7"
                  />
                </svg>
                Previous
              </button>

              {/* Page Numbers */}
              <div className="flex space-x-1">
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(
                  (page) => (
                    <button
                      key={page}
                      onClick={() => {
                        setCurrentPage(page);
                        if (activeTab === "users")
                          fetchUsers(page, searchTerm, 10);
                        else if (activeTab === "projects")
                          fetchProjects(page, statusFilter, searchTerm, 10);
                        else if (activeTab === "transactions")
                          fetchTransactions(page, statusFilter, searchTerm, 10);
                      }}
                      className={`min-w-[40px] h-10 px-3 rounded-lg font-medium transition-all duration-200 ${
                        currentPage === page
                          ? "bg-gradient-to-r from-purple-500 to-pink-500 text-white shadow-lg shadow-purple-500/25 transform scale-105"
                          : "bg-white/10 text-gray-300 hover:text-white hover:bg-white/20 hover:shadow-md"
                      }`}
                    >
                      {page}
                    </button>
                  )
                )}
              </div>

              {/* Next Button */}
              <button
                onClick={() => {
                  if (currentPage < totalPages) {
                    const newPage = currentPage + 1;
                    setCurrentPage(newPage);
                    if (activeTab === "users")
                      fetchUsers(newPage, searchTerm, 10);
                    else if (activeTab === "projects")
                      fetchProjects(newPage, statusFilter, searchTerm, 10);
                    else if (activeTab === "transactions")
                      fetchTransactions(newPage, statusFilter, searchTerm, 10);
                  }
                }}
                disabled={currentPage === totalPages}
                className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 flex items-center ${
                  currentPage === totalPages
                    ? "bg-gray-700/50 text-gray-500 cursor-not-allowed"
                    : "bg-white/10 text-gray-300 hover:text-white hover:bg-white/20 hover:shadow-lg"
                }`}
              >
                Next
                <svg
                  className="w-4 h-4 ml-1"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </button>
            </div>
          )}

        {/* Page Info */}
        {(activeTab === "users" ||
          activeTab === "projects" ||
          activeTab === "transactions") &&
          totalPages > 0 && (
            <div className="text-center mt-4">
              <p className="text-gray-400 text-sm">
                Page {currentPage} of {totalPages}
                {activeTab === "users" &&
                  users.length > 0 &&
                  ` • ${users.length} users shown`}
                {activeTab === "projects" &&
                  projects.length > 0 &&
                  ` • ${projects.length} projects shown`}
                {activeTab === "transactions" &&
                  transactions.length > 0 &&
                  ` • ${transactions.length} transactions shown`}
              </p>
            </div>
          )}
      </div>
    </div>
  );
}
