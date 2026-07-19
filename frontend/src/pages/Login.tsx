import { useNavigate } from "react-router-dom";
import Background from "../components/auth/Background";
import LoginCard from "../components/auth/LoginCard";

export default function Login() {
  const navigate = useNavigate();

  const handleLogin = () => {
    // Save login session
    localStorage.setItem("codex-auth", "true");

    // Go to dashboard
    navigate("/dashboard");
  };

  return (
    <Background>
      <LoginCard onLogin={handleLogin} />
    </Background>
  );
}