interface Props {
  websiteId: number;
}

export default function Overview({ websiteId }: Props) {
  return (
    <div className="grid gap-6 md:grid-cols-2">

      <div className="rounded-xl border border-slate-700 bg-slate-900 p-6">
        <h3 className="mb-4 text-xl font-bold text-white">
          Website Information
        </h3>

        <div className="space-y-3 text-slate-300">
          <p><strong>ID:</strong> {websiteId}</p>
          <p><strong>Domain:</strong> example.com</p>
          <p><strong>Runtime:</strong> Node.js</p>
          <p><strong>Status:</strong> Running</p>
          <p><strong>SSL:</strong> Enabled</p>
          <p><strong>Owner:</strong> Admin</p>
          <p><strong>Root:</strong> /var/www/example</p>
        </div>
      </div>

      <div className="rounded-xl border border-slate-700 bg-slate-900 p-6">
        <h3 className="mb-4 text-xl font-bold text-white">
          Resource Usage
        </h3>

        <div className="space-y-3 text-slate-300">
          <p>CPU Usage: 18%</p>
          <p>RAM Usage: 1.2 / 4 GB</p>
          <p>Disk Usage: 6.5 / 20 GB</p>
          <p>Bandwidth: 420 MB</p>
        </div>
      </div>

    </div>
  );
}