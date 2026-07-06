'use client';

import { motion } from 'framer-motion';

const steps = [
  {
    num: '01',
    title: 'DISCOVER',
    desc: 'Analyzing data metrics, API schemas, and vector pipeline boundaries.',
    icon: (
      <svg className="w-5 h-5 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    ),
  },
  {
    num: '02',
    title: 'STRATEGIZE',
    desc: 'Mapping search patterns, indexing databases, and designing security scopes.',
    icon: (
      <svg className="w-5 h-5 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    ),
  },
  {
    num: '03',
    title: 'DESIGN',
    desc: 'Creating database architectures, layout flows, and robust backend endpoints.',
    icon: (
      <svg className="w-5 h-5 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
      </svg>
    ),
  },
  {
    num: '04',
    title: 'DEVELOP',
    desc: 'Writing clean FastAPI code, setting up ingestion scripts, and building UI modules.',
    icon: (
      <svg className="w-5 h-5 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
      </svg>
    ),
  },
  {
    num: '05',
    title: 'DELIVER',
    desc: 'Orchestrating container pipelines, launching endpoints, and compiling builds.',
    icon: (
      <svg className="w-5 h-5 text-[#ef4444]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
      </svg>
    ),
  },
];

const container = {
  hidden: {},
  show: { transition: { staggerChildren: 0.1 } },
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.25, 0.1, 0.25, 1] } },
};

export default function Process() {
  return (
    <section className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24">
      {/* Subtle top line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        {/* Section Header */}
        <div className="relative mb-20">
          <motion.p
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]"
          >
            Work Process
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="text-3xl font-black tracking-tight sm:text-4xl text-white uppercase"
          >
            Development Path
          </motion.h2>
          <div className="absolute -bottom-4 left-0 w-12 h-[2.5px] bg-[#ef4444]" />
        </div>

        {/* Timeline Grid */}
        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: '-50px' }}
          className="grid gap-8 md:grid-cols-5"
        >
          {steps.map((step, idx) => (
            <motion.div
              key={step.title}
              variants={item}
              className="relative flex flex-col items-start group"
            >
              {/* Step Header info */}
              <div className="flex items-baseline gap-2 mb-4">
                <span className="text-sm font-black text-[#ef4444]/60 group-hover:text-[#ef4444] transition-colors duration-300">
                  {step.num}
                </span>
                <h3 className="text-sm font-black tracking-wider text-white group-hover:text-white transition-colors duration-300">
                  {step.title}
                </h3>
              </div>

              {/* Icon Holder */}
              <div className="mb-6 p-3.5 rounded-xl border border-white/[0.05] bg-white/[0.01] transition-all duration-300 group-hover:border-[#ef4444]/30 group-hover:bg-[#ef4444]/5 group-hover:shadow-[0_0_20px_rgba(239,68,68,0.1)]">
                {step.icon}
              </div>

              {/* Timeline Connector Line & Dot */}
              <div className="relative w-full flex items-center mb-6">
                {/* Horizontal line connector (hidden on last step) */}
                {idx < 4 && (
                  <div className="hidden md:block absolute left-4 right-0 h-[1.5px] bg-gradient-to-r from-[#ef4444]/35 via-white/[0.04] to-white/[0.04]" />
                )}
                
                {/* Pulsing indicator node */}
                <div className="h-2.5 w-2.5 rounded-full border border-[#ef4444] bg-[#0a0a0a] z-10 flex items-center justify-center transition-all duration-300 group-hover:scale-125 group-hover:border-white">
                  <span className="h-1 w-1 rounded-full bg-[#ef4444] group-hover:bg-white" />
                </div>
              </div>

              {/* Step Description */}
              <p className="text-xs sm:text-[13px] leading-relaxed text-white/50 group-hover:text-white/60 transition-colors duration-300 text-left">
                {step.desc}
              </p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
