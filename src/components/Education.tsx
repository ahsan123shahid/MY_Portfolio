'use client';

import { motion } from 'framer-motion';

const education = [
  {
    degree: 'BS Artificial Intelligence (Final Year)',
    school: 'ARID Agriculture University, BIIT',
    period: '2023 – 2027',
  },
  {
    degree: 'FSC Pre-Engineering',
    school: 'Steps College',
    period: '2020 – 2022',
  },
];

const certs = [
  'BIIT AI Hackathon — 3rd Place, Arid Agriculture University (2024)',
  'Cisco Certified Network Associate (CCNA) — Corvit Systems, Rawalpindi (2022)',
];

const languages = [
  { name: 'English', level: 'Fluent' },
  { name: 'Urdu', level: 'Native' },
  { name: 'Punjabi', level: 'Fluent' },
];

export default function Education() {
  return (
    <section
      id="background"
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
            Background
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="text-3xl font-black tracking-tight sm:text-4xl text-white uppercase"
          >
            Education &amp; More
          </motion.h2>
          <div className="absolute -bottom-4 left-0 w-12 h-[2.5px] bg-[#ef4444]" />
        </div>

        <div className="grid gap-8 lg:grid-cols-3">
          {/* Education */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.1, 0.25, 1] }}
            className="group relative rounded-2xl border border-white/[0.06] bg-white/[0.01] p-6 backdrop-blur-md transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
          >
            <div className="absolute top-0 left-6 right-6 h-[1.5px] bg-gradient-to-r from-transparent via-[#ef4444]/20 to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
            <h3 className="mb-6 text-xs font-bold tracking-[0.2em] uppercase text-white/30 group-hover:text-[#ef4444] transition-colors duration-300">
              Education
            </h3>
            <div className="relative space-y-8 pl-1">
              <div className="absolute left-[3.5px] top-1.5 bottom-1.5 w-[1px] bg-gradient-to-b from-[#ef4444]/40 via-[#ef4444]/10 to-transparent" />
              {education.map((e) => (
                <div
                  key={e.degree}
                  className="relative pl-6 group/item"
                >
                  {/* node dot */}
                  <div className="absolute left-0 top-[3px] h-2 w-2 -translate-x-[3.5px] rounded-full border border-[#ef4444] bg-[#0a0a0a] z-10 transition-transform duration-300 group-hover/item:scale-125" />
                  <p className="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/30 group-hover/item:text-[#ef4444] transition-colors duration-300">
                    {e.period}
                  </p>
                  <p className="mt-1 text-sm font-semibold text-white/80 group-hover/item:text-white transition-colors duration-300">{e.degree}</p>
                  <p className="text-xs text-white/40">{e.school}</p>
                </div>
              ))}
            </div>
          </motion.div>

          {/* Certifications */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.1, ease: [0.25, 0.1, 0.25, 1] }}
            className="group relative rounded-2xl border border-white/[0.06] bg-white/[0.01] p-6 backdrop-blur-md transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
          >
            <div className="absolute top-0 left-6 right-6 h-[1.5px] bg-gradient-to-r from-transparent via-[#ef4444]/20 to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
            <h3 className="mb-6 text-xs font-bold tracking-[0.2em] uppercase text-white/30 group-hover:text-[#ef4444] transition-colors duration-300">
              Certifications &amp; Awards
            </h3>
            <ul className="space-y-4">
              {certs.map((c) => (
                <li
                  key={c}
                  className="flex items-start gap-3 text-xs leading-relaxed text-white/50 group-hover:text-white/70 transition-colors duration-300"
                >
                  <span className="mt-[6px] h-1.5 w-1.5 shrink-0 rounded-full bg-[#ef4444]/40" />
                  {c}
                </li>
              ))}
            </ul>
          </motion.div>

          {/* Languages */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2, ease: [0.25, 0.1, 0.25, 1] }}
            className="group relative rounded-2xl border border-white/[0.06] bg-white/[0.01] p-6 backdrop-blur-md transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
          >
            <div className="absolute top-0 left-6 right-6 h-[1.5px] bg-gradient-to-r from-transparent via-[#ef4444]/20 to-transparent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
            <h3 className="mb-6 text-xs font-bold tracking-[0.2em] uppercase text-white/30 group-hover:text-[#ef4444] transition-colors duration-300">
              Languages
            </h3>
            <div className="space-y-3">
              {languages.map((l) => (
                <div
                  key={l.name}
                  className="flex items-center justify-between rounded-xl border border-white/[0.04] bg-white/[0.01] px-4 py-3 hover:border-white/10 hover:bg-white/[0.02] transition-all duration-350"
                >
                  <span className="text-xs font-semibold text-white/80">{l.name}</span>
                  <span className="text-[9px] font-semibold uppercase tracking-[0.15em] text-white/45">
                    {l.level}
                  </span>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
