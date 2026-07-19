import { Navigate } from "react-router-dom";

interface Props {
  children: React.ReactNode;
}

export default function ProtectedRoute({ children }: Props) {
  const loggedIn = localStorage.getItem("codex-auth");

  if (!loggedIn) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
}