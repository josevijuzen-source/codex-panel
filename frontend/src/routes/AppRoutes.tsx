import { Routes, Route } from "react-router-dom";

import Login from "../pages/Login";
import Dashboard from "../pages/Dashboard";
import Websites from "../pages/Websites";
import FileManager from "../pages/FileManager";
import Terminal from "../pages/Terminal";
import Databases from "../pages/Databases";
import SSL from "../pages/SSL";
import Backups from "../pages/Backups";
import Users from "../pages/Users";
import Settings from "../pages/Settings";
import NotFound from "../pages/NotFound";
import Server from "../pages/Server";
import Logs from "../pages/Logs";
import Email from "../pages/Email";
import WordPress from "../pages/WordPress";
import DNS from "../pages/DNS";
import FTP from "../pages/FTP";
import Domains from "../pages/Domains";



import DashboardLayout from "../layouts/DashboardLayout";
import ProtectedRoute from "./ProtectedRoute";

import WebsiteManager from "../components/websites/WebsiteManager";

export default function AppRoutes() {
  return (
    <Routes>
      {/* Login */}
      <Route path="/" element={<Login />} />

      {/* Dashboard */}
      <Route
  path="/dashboard"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <Dashboard />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* WordPress */}
<Route
  path="/wordpress"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <WordPress />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

<Route
  path="/wordpress"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <WordPress />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* DNS */}
<Route
  path="/dns"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <DNS />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* Domains */}
<Route
  path="/domains"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <Domains />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* FTP */}
<Route
  path="/ftp"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <FTP />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

<Route
  path="/email"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <Email />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* Logs */}
<Route
  path="/logs"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <Logs />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

{/* Server */}
<Route
  path="/server"
  element={
    <ProtectedRoute>
      <DashboardLayout>
        <Server />
      </DashboardLayout>
    </ProtectedRoute>
  }
/>

      {/* Websites */}
      <Route
        path="/websites"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Websites />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Website Manager */}
      <Route
        path="/websites/:id"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <WebsiteManager />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* File Manager */}
      <Route
        path="/file-manager"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <FileManager />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Terminal */}
      <Route
        path="/terminal"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Terminal />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Databases */}
      <Route
        path="/databases"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Databases />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* SSL */}
      <Route
        path="/ssl"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <SSL />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Backups */}
      <Route
        path="/backups"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Backups />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Users */}
      <Route
        path="/users"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Users />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* Settings */}
      <Route
        path="/settings"
        element={
          <ProtectedRoute>
            <DashboardLayout>
              <Settings />
            </DashboardLayout>
          </ProtectedRoute>
        }
      />

      {/* 404 */}
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}