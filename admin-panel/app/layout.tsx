import "./globals.css";
import { Toaster } from "react-hot-toast";

export const metadata = {
  title: "CloneX - Admin Panel",
  description: "Admin dashboard for CloneX video generation platform",
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="en">
      <body>
        {children}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: "rgba(15, 23, 42, 0.9)",
              color: "#fff",
              border: "1px solid rgba(147, 51, 234, 0.3)",
              backdropFilter: "blur(10px)",
            },
            success: {
              iconTheme: {
                primary: "#10B981",
                secondary: "#fff",
              },
            },
            error: {
              iconTheme: {
                primary: "#EF4444",
                secondary: "#fff",
              },
            },
          }}
        />
      </body>
    </html>
  );
}
