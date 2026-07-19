import { useState } from "react";
import { Eye, EyeOff, Lock } from "lucide-react";

interface PasswordInputProps {
  password: string;
  setPassword: (value: string) => void;
}

export default function PasswordInput({
  password,
  setPassword,
}: PasswordInputProps) {
  const [showPassword, setShowPassword] = useState(false);

  return (
    <div>
      <label className="mb-2 block text-sm text-slate-300">
        Password
      </label>

      <div className="relative">

        <Lock
          size={18}
          className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500"
        />

        <input
          type={showPassword ? "text" : "password"}
          placeholder="Enter your password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-xl border border-slate-700 bg-slate-950 py-3 pl-11 pr-12 text-white outline-none transition focus:border-blue-500"
          required
        />

        <button
          type="button"
          onClick={() => setShowPassword(!showPassword)}
          className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-500 hover:text-blue-400 transition"
        >
          {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
        </button>

      </div>
    </div>
  );
}