import { useState } from "react";
import PasswordInput from "./PasswordInput";

export default function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();

    console.log({
      email,
      password,
      remember,
    });

    alert("Backend authentication coming soon!");
  };

  return (
    <form onSubmit={handleLogin} className="space-y-5">

      <div>
        <label className="mb-2 block text-sm text-slate-300">
          Email Address
        </label>

        <input
          type="email"
          placeholder="admin@codexpanel.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-xl border border-slate-700 bg-slate-950 px-4 py-3 text-white outline-none transition focus:border-blue-500"
          required
        />
      </div>

      <PasswordInput
        password={password}
        setPassword={setPassword}
      />

      <div className="flex items-center justify-between text-sm">

        <label className="flex items-center gap-2 text-slate-400">

          <input
            type="checkbox"
            checked={remember}
            onChange={() => setRemember(!remember)}
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
        type="submit"
        className="w-full rounded-xl bg-blue-600 py-3 text-lg font-semibold text-white transition hover:bg-blue-700"
      >
        Login to Dashboard
      </button>

    </form>
  );
}