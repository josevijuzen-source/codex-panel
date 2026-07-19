import { useState } from "react";
import { Eye, EyeOff, Lock, Shield } from "lucide-react";

interface Props {
  onLogin: () => void;
}

export default function LoginCard({ onLogin }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(false);

  const handleLogin = () => {
    if (
      email.trim() === "admin@codexpanel.com" &&
      password === "admin123"
    ) {
      onLogin();
    } else {
      alert("❌ Invalid email or password");
    }
  };

  return (
    <div className="w-[520px] rounded-3xl border border-slate-700 bg-slate-900/90 p-10 shadow-2xl backdrop-blur-xl">

      <div className="mb-8 flex justify-center">
        <div className="flex h-24 w-24 items-center justify-center rounded-full border border-blue-700 bg-blue-900/40">
          <Shield className="h-12 w-12 text-sky-400" />
        </div>
      </div>

      <h1 className="text-center text-5xl font-bold text-white">
        Codex Panel
      </h1>

      <p className="mt-3 text-center text-xl text-slate-400">
        Next Generation Hosting Platform
      </p>

      <div className="mt-10">

        <label className="mb-2 block text-sm font-semibold text-slate-300">
          Email Address
        </label>

        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="admin@codexpanel.com"
          className="mb-6 w-full rounded-xl border border-slate-700 bg-slate-950 px-5 py-4 text-white outline-none transition focus:border-blue-500"
        />

        <label className="mb-2 block text-sm font-semibold text-slate-300">
          Password
        </label>

        <div className="relative">

          <Lock className="absolute left-4 top-4 text-slate-500" size={20} />

          <input
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            className="w-full rounded-xl border border-slate-700 bg-slate-950 py-4 pl-12 pr-12 text-white outline-none transition focus:border-blue-500"
          />

          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-4 top-4 text-slate-500 hover:text-white"
          >
            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
          </button>

        </div>

        <div className="mt-6 flex items-center justify-between">

          <label className="flex items-center gap-2 text-slate-400">
            <input
              type="checkbox"
              checked={remember}
              onChange={(e) => setRemember(e.target.checked)}
            />
            Remember Me
          </label>

          <button
            type="button"
            className="text-blue-400 hover:text-blue-300"
          >
            Forgot Password?
          </button>

        </div>

        <button
          type="button"
          onClick={handleLogin}
          className="mt-8 w-full rounded-xl bg-blue-600 py-4 text-xl font-semibold text-white transition hover:bg-blue-700"
        >
          Login to Dashboard
        </button>

        <div className="mt-8 border-t border-slate-700 pt-6 text-center text-slate-500">
          Ubuntu 24.04 • Docker • Nginx • MariaDB
        </div>

      </div>

    </div>
  );
}