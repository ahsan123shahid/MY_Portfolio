'use client';

import { motion, useMotionValue, useTransform, useSpring } from 'framer-motion';
import { MouseEvent } from 'react';

const focusAreas = [
  { title: 'AI Engineering', desc: 'Custom RAG architectures, agent pipelines, and vector database structures.' },
  { title: 'Full-Stack Development', desc: 'Secure backend APIs in FastAPI / ASP.NET alongside modern UI wrappers.' },
  { title: 'Cross-Platform Mobile', desc: 'Sleek, native mobile/desktop apps built in Flutter.' },
  { title: 'Cloud Infrastructure', desc: 'Containerized environments via Docker and cloud deployment setups.' },
];

const progressSkills = [
  { name: 'AI Engineering & LLMs', percentage: 95 },
  { name: 'RAG & Vector Pipelines', percentage: 92 },
  { name: 'Full-Stack Development', percentage: 90 },
  { name: 'Backend API Architectures', percentage: 88 },
  { name: 'Mobile App Engineering (Flutter)', percentage: 85 },
];

const techStacks = [
  {
    label: 'Backend & Frameworks',
    skills: ['FastAPI', 'Flask', 'ASP.NET Core', 'SQLAlchemy', 'JWT Auth', 'REST APIs'],
  },
  {
    label: 'Databases & Cloud',
    skills: ['PostgreSQL', 'SQL Server', 'MySQL', 'SQLite', 'Docker', 'AWS EC2', 'Vercel'],
  },
  {
    label: 'Languages',
    skills: ['Python', 'Dart', 'C#', 'JavaScript', 'SQL', 'HTML5', 'CSS3'],
  },
];

const container = {
  hidden: {},
  show: { transition: { staggerChildren: 0.1 } },
};

const item = {
  hidden: { opacity: 0, y: 25 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5, ease: [0.25, 0.1, 0.25, 1] } },
};

function StackCard({ group }: { group: typeof techStacks[0] }) {
  const x = useMotionValue(0.5);
  const y = useMotionValue(0.5);

  const rotateX = useSpring(useTransform(y, [0, 1], [10, -10]), { stiffness: 150, damping: 18 });
  const rotateY = useSpring(useTransform(x, [0, 1], [-10, 10]), { stiffness: 150, damping: 18 });

  function handleMouseMove(event: MouseEvent<HTMLDivElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    x.set((event.clientX - rect.left) / rect.width);
    y.set((event.clientY - rect.top) / rect.height);
  }

  function handleMouseLeave() {
    x.set(0.5);
    y.set(0.5);
  }

  return (
    <div className="perspective-1000">
      <motion.div
        variants={item}
        onMouseMove={handleMouseMove}
        onMouseLeave={handleMouseLeave}
        style={{ rotateX, rotateY, transformStyle: 'preserve-3d' }}
        className="group relative rounded-2xl border border-white/[0.05] bg-white/[0.01] p-6 backdrop-blur-md transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
      >
        <div className="absolute top-0 left-6 right-6 h-[1.5px] bg-gradient-to-r from-transparent via-[#ef4444]/15 to-transparent" />
        <p className="mb-4 text-[10px] font-bold uppercase tracking-[0.2em] text-[#ef4444] group-hover:text-white transition-colors duration-300">
          {group.label}
        </p>
        <div className="flex flex-wrap gap-1.5" style={{ transform: 'translateZ(15px)' }}>
          {group.skills.map((s) => (
            <motion.span
              key={s}
              whileHover={{ scale: 1.05 }}
              className="cursor-default rounded-md border border-white/[0.06] bg-white/[0.02] px-2.5 py-1.5 text-xs text-white/50 transition-all duration-200 hover:border-[#ef4444]/30 hover:bg-[#ef4444]/5 hover:text-white"
            >
              {s}
            </motion.span>
          ))}
        </div>
      </motion.div>
    </div>
  );
}

export default function Skills() {
  return (
    <section className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24">
      {/* Subtle top line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="grid gap-16 lg:grid-cols-12 items-start mb-20">
          {/* Left Column: Creative Title & Slogan */}
          <div className="lg:col-span-5 text-left">
            <span className="inline-block mb-3 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]">
              Services &amp; Focus
            </span>
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black leading-[0.95] tracking-tighter uppercase text-white mb-6 select-none">
              STRATEGIC INTELLIGENCE. <br />
              MEASURABLE <span className="text-[#ef4444]">IMPACT.</span>
            </h2>
            <p className="text-sm leading-relaxed text-white/50 mb-10">
              I build custom AI architectures and database pipelines. Not just loading pre-packaged wrappers, but designing production systems optimized for scale and precision.
            </p>

            {/* Focus list with custom red check nodes */}
            <div className="space-y-4">
              {focusAreas.map((f, i) => (
                <div key={i} className="flex gap-4 items-start">
                  <span className="mt-[5px] h-2 w-2 shrink-0 rounded-full bg-[#ef4444]" />
                  <div>
                    <h4 className="text-xs font-black uppercase text-white/80 tracking-wider mb-0.5">{f.title}</h4>
                    <p className="text-xs text-white/40">{f.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right Column: Skills Progress Bars */}
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-block text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444] mb-2">
              Capabilities
            </span>
            {progressSkills.map((s) => (
              <div key={s.name} className="relative">
                <div className="flex justify-between text-xs font-bold uppercase tracking-wider text-white/80 mb-2">
                  <span>{s.name}</span>
                  <span className="text-[#ef4444]">{s.percentage}%</span>
                </div>
                <div className="h-1.5 w-full rounded-full bg-white/[0.04] overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    whileInView={{ width: `${s.percentage}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 1.2, ease: 'easeOut' }}
                    className="h-full bg-gradient-to-r from-[#ef4444] to-[#ff6b6b]"
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Stack Cards section */}
        <div className="border-t border-white/[0.04] pt-16">
          <div className="relative mb-12">
            <h3 className="text-sm font-semibold uppercase tracking-[0.25em] text-[#ef4444] mb-3">
              Full Stack Directory
            </h3>
            <div className="absolute bottom-0 left-0 w-12 h-[1px] bg-[#ef4444]/40" />
          </div>

          <motion.div
            variants={container}
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: '-50px' }}
            className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3"
          >
            {techStacks.map((g) => (
              <StackCard key={g.label} group={g} />
            ))}
          </motion.div>
        </div>
      </div>
    </section>
  );
}
