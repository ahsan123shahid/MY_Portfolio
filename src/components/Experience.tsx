'use client';

import { motion } from 'framer-motion';

const jobs = [
  {
    role: 'IT Manager & Full-Stack Developer',
    company: 'RT International (UK Energy Broker)',
    period: '2022 – Present',
    highlights: [
      'Built the company\'s internal CRM backend from scratch using FastAPI + PostgreSQL, replacing manual spreadsheet workflows.',
      'Implemented RBAC with JWT — three separate access scopes (Agent, Manager, Admin) with scoped data visibility.',
      'Built AI-powered data extraction pipelines that parse unstructured sales notes into structured UK energy schemas.',
      'Resolved critical production issues including Vercel serverless DB connection failures, SQL injection vectors, and Pydantic v2 serialization bugs.',
      'Manage day-to-day IT setup and infrastructure maintenance for the office.',
    ],
  },
];

export default function Experience() {
  return (
    <section
      id="experience"
      className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24"
    >
      {/* Subtle top section line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="relative mb-16">
          <motion.p
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]"
          >
            Experience
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="text-3xl font-black tracking-tight sm:text-4xl text-white uppercase"
          >
            Work History
          </motion.h2>
          <div className="absolute -bottom-4 left-0 w-12 h-[2.5px] bg-[#ef4444]" />
        </div>

        <div className="relative space-y-12 pl-1">
          {/* Custom timeline gradient line */}
          <div className="absolute left-[5.5px] top-2 bottom-2 w-[1.5px] bg-gradient-to-b from-[#ef4444]/55 via-[#ef4444]/20 to-transparent" />

          {jobs.map((j, idx) => (
            <motion.div
              key={j.company}
              initial={{ opacity: 0, x: -12 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: idx * 0.15, ease: [0.25, 0.1, 0.25, 1] }}
              className="relative pl-8 group"
            >
              {/* Pulsing timeline node */}
              <div className="absolute left-0 top-[26px] h-3 w-3 -translate-x-[5.5px] rounded-full border border-[#ef4444] bg-[#0a0a0a] z-10 flex items-center justify-center transition-all duration-300 group-hover:border-white group-hover:scale-125">
                <span className="h-1 w-1 rounded-full bg-[#ef4444] group-hover:bg-white transition-colors" />
              </div>

              {/* Glass Details Card */}
              <div className="rounded-2xl border border-white/[0.04] bg-white/[0.01] p-6 backdrop-blur-md transition-all duration-300 hover:border-white/[0.1] hover:bg-white/[0.02]">
                <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-[#ef4444]">
                  {j.period}
                </p>
                <h3 className="mt-1.5 text-xl font-bold tracking-tight text-white">
                  {j.role}
                </h3>
                <p className="mb-4 text-xs font-semibold text-white/40">
                  {j.company}
                </p>
                
                <ul className="space-y-3">
                  {j.highlights.map((h, i) => (
                    <li
                      key={i}
                      className="flex items-start gap-3 text-xs sm:text-sm leading-relaxed text-white/50 group-hover:text-white/60 transition-colors duration-300"
                    >
                      <span className="mt-[7px] h-1.5 w-1.5 shrink-0 rounded-full bg-[#ef4444]/40 group-hover:bg-[#ef4444] transition-colors duration-300" />
                      {h}
                    </li>
                  ))}
                </ul>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
