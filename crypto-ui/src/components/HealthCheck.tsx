import { CheckCircleIcon, XCircleIcon } from "@heroicons/react/24/solid";
import clsx from "clsx";
import { useEffect, useRef } from "react";

interface HealthCheckProps {
  health: { status?: string; error?: string; timestamp?: string } | null;
  show: boolean;
  onClose: () => void;
}

export default function HealthCheck({ health, show, onClose }: HealthCheckProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  // Fecha ao clicar fora
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        onClose();
      }
    }
    if (show) document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [show, onClose]);

  // Fecha automaticamente após 10s
  useEffect(() => {
    if (!show) return;
    const timer = setTimeout(onClose, 10000);
    return () => clearTimeout(timer);
  }, [show, onClose]);

  if (!show || !health) return null;

  const isError = !!health.error;

  // Formata timestamp se existir
  const formattedDate = health.timestamp
    ? new Date(health.timestamp).toLocaleString("pt-BR", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      })
    : null;

  return (
    <section
      ref={containerRef}
      className={clsx(
        "max-w-3xl mx-auto mt-4 p-4 md:p-6 rounded-xl shadow-lg bg-white border transition-all transform hover:scale-[1.02]",
        isError ? "border-red-400" : "border-green-400",
        "animate-fade-in"
      )}
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {isError ? (
            <XCircleIcon className="w-6 h-6 text-red-500 animate-pulse" />
          ) : (
            <CheckCircleIcon className="w-6 h-6 text-green-500 animate-bounce" />
          )}
          <h3 className="text-lg md:text-xl font-semibold text-gray-700">
            {isError ? "API OFFLINE" : "API ONLINE"}
          </h3>
        </div>

        {formattedDate && (
          <span
            className={clsx(
              "px-3 py-1 rounded-full text-sm font-medium",
              isError ? "bg-red-100 text-red-700" : "bg-green-100 text-green-700"
            )}
          >
            {formattedDate}
          </span>
        )}
      </div>
    </section>
  );
}
