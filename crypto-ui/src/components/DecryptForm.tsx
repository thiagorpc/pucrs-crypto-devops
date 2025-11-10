import { ClipboardIcon, LockOpenIcon } from "@heroicons/react/24/solid";
import { useState } from "react";

interface DecryptFormProps {
  payload: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  loading: boolean;
  result: string | null;
}

function ResultArea({ result, title }: { result: string; title: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(result);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="mt-6 space-y-3">
      <label htmlFor="payload" className="block text-gray-700 font-medium">
        {title}
      </label>
      <pre className="bg-gray-100 text-gray-800 p-4 rounded-md text-sm md:text-base overflow-x-auto whitespace-pre-wrap break-all shadow-inner">
        {result}
      </pre>
      <button
        onClick={handleCopy}
        className="w-full md:w-auto px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-md shadow-md transition-all flex items-center justify-center gap-2"
      >
        <ClipboardIcon className="w-5 h-5" />
        {copied ? "Copiado!" : "Copiar resultado"}
      </button>
    </div>
  );
}

export default function DecryptForm({
  payload,
  onChange,
  onSubmit,
  loading,
  result,
}: DecryptFormProps) {
  return (
    <section className="bg-white p-6 md:p-8 rounded-xl shadow-lg max-w-3xl mx-auto">
      <h2 className="text-2xl md:text-2xl font-extrabold text-gray-700 mb-6 border-b pb-2 flex items-center gap-2">
        <LockOpenIcon className="w-6 h-6 text-orange-500" />
        Descriptografar com AES 256 GCM
      </h2>

      <div className="space-y-4">
        <label htmlFor="payloadDecrypt" className="block text-gray-700 font-medium">
          Digite o texto criptografado:
        </label>

        <textarea
          id="payloadDecrypt"
          value={payload}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Ex: Ciphertext recebido da API..."
          className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm md:text-base focus:outline-none focus:ring-4 focus:ring-blue-200 transition-shadow resize-y whitespace-pre-wrap break-all"
          rows={2}
        />

        <button
          onClick={onSubmit}
          disabled={loading || !payload}
          className={`w-full md:w-auto px-4 py-2 text-white font-bold rounded-md shadow-md transition-all flex items-center justify-center gap-2 ${
            loading || !payload
              ? "bg-gray-400 cursor-not-allowed"
              : "bg-orange-500 hover:bg-orange-600"
          }`}
        >
          {loading ? "Aguarde..." : "Descriptografar"}
        </button>
      </div>

      {result && <ResultArea result={result} title="Resultado da Descriptografia" />}
    </section>
  );
}
