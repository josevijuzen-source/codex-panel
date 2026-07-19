interface Props {
  title: string;
  value: string;
  color: string;
}

export default function StatCard({ title, value, color }: Props) {
  return (
    <div className="rounded-2xl bg-slate-800 p-6 shadow-lg border border-slate-700">
      <h3 className="text-slate-400 text-sm">{title}</h3>

      <h1 className={`mt-3 text-4xl font-bold ${color}`}>
        {value}
      </h1>
    </div>
  );
}