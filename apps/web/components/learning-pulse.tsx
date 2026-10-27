"use client";

import { useState } from "react";
import { ArrowUpRight, TrendingUp } from "lucide-react";

const datasets = {
  Week: {
    labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    values: [22, 31, 24, 42, 36, 48, 55],
  },
  Month: {
    labels: [
      "01 Oct",
      "05 Oct",
      "10 Oct",
      "15 Oct",
      "20 Oct",
      "25 Oct",
      "30 Oct",
    ],
    values: [93, 128, 114, 171, 148, 196, 224],
  },
};

export function LearningPulse() {
  const [period, setPeriod] = useState<"Week" | "Month">("Week");
  const [focused, setFocused] = useState<number | null>(null);
  const data = datasets[period];
  const maximum = Math.ceil(Math.max(...data.values) / 20) * 20;
  const points = data.values
    .map(
      (value, index) => `${48 + index * 73},${152 - (value / maximum) * 112}`,
    )
    .join(" ");
  const total = data.values.reduce((sum, value) => sum + value, 0);

  return (
    <section className="pulse-panel" aria-labelledby="pulse-title">
      <div className="section-heading">
        <div>
          <span className="eyebrow">A LITTLE PROGRESS, EVERY DAY</span>
          <h2 id="pulse-title">
            Learning pulse <TrendingUp size={18} />
          </h2>
        </div>
        <div className="period-tabs" aria-label="Activity period">
          {(["Week", "Month"] as const).map((item) => (
            <button
              key={item}
              aria-pressed={period === item}
              onClick={() => {
                setPeriod(item);
                setFocused(null);
              }}
            >
              {item}
            </button>
          ))}
        </div>
      </div>
      <div className="pulse-summary">
        <strong>{total.toLocaleString()}</strong>
        <div>
          <span>activities completed</span>
          <small>Sample {period.toLowerCase()} · October 2026</small>
        </div>
        <span className="pulse-trend">
          <ArrowUpRight size={15} />
          Building momentum
        </span>
      </div>
      <svg
        className="pulse-chart"
        viewBox="0 0 535 190"
        role="img"
        aria-label={`${period} sample activity: ${data.labels.map((label, i) => `${label}: ${data.values[i]}`).join(", ")}`}
      >
        <defs>
          <linearGradient id="pulse-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#a9caa1" stopOpacity=".5" />
            <stop offset="100%" stopColor="#a9caa1" stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0, 1, 2, 3].map((row) => (
          <g key={row}>
            <line
              x1="48"
              y1={40 + row * 37.3}
              x2="500"
              y2={40 + row * 37.3}
              stroke="#e6eae3"
              strokeDasharray="3 5"
            />
            <text x="32" y={44 + row * 37.3} textAnchor="end">
              {Math.round((maximum * (3 - row)) / 3)}
            </text>
          </g>
        ))}
        <polygon points={`48,152 ${points} 486,152`} fill="url(#pulse-fill)" />
        <polyline
          points={points}
          fill="none"
          stroke="#2d6951"
          strokeWidth="3"
          strokeLinejoin="round"
          strokeLinecap="round"
        />
        {data.values.map((value, i) => (
          <g key={i}>
            <circle
              cx={48 + i * 73}
              cy={152 - (value / maximum) * 112}
              r={focused === i ? 6 : 4}
              fill={focused === i ? "#d9f17b" : "#fff"}
              stroke="#2d6951"
              strokeWidth="2"
            />
            <text x={48 + i * 73} y="179" textAnchor="middle">
              {data.labels[i]}
            </text>
          </g>
        ))}
      </svg>
      <div className="chart-values" aria-label="Explore activity values">
        {data.values.map((value, i) => (
          <button
            key={i}
            onFocus={() => setFocused(i)}
            onMouseEnter={() => setFocused(i)}
            onBlur={() => setFocused(null)}
            onMouseLeave={() => setFocused(null)}
            onClick={() => setFocused(i)}
            aria-pressed={focused === i}
          >
            <span>{data.labels[i]}</span>
            <strong>{value}</strong>
          </button>
        ))}
      </div>
    </section>
  );
}
