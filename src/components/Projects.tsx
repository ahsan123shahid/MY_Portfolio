'use client';

import { motion, useMotionValue, useTransform, useSpring } from 'framer-motion';
import { MouseEvent } from 'react';

const projects = [
  {
    title: 'BIIT Question Generator',
    role: 'FYP — Full-Stack AI',
    desc: 'FastAPI backend with JWT auth and SQL Server handling quiz generation, study notes, and student attempt tracking. PDF ingestion pipeline that reads academic lecture PDFs and extracts topics. Gemini integration for async MCQ generation. Smart quiz recommendation engine that avoids repeating recently seen questions. Full Flutter mobile app with quiz, results, study notes, and AI explanation mode.',
    tags: ['FastAPI', 'SQL Server', 'Gemini', 'Ollama', 'Flutter'],
    glow: 'rgba(239, 68, 68, 0.15)', // Crimson Red
  },
  {
    title: 'RT International CRM',
    role: 'Full-Stack Development',
    desc: 'Full lead lifecycle management with callback scheduling, financial detail handling, and secure UK energy data schemas. Multi-role backend architecture with RBAC enforced via JWT claims. Deployed via Docker on Vercel with production-grade error handling.',
    tags: ['FastAPI', 'PostgreSQL', 'SQLAlchemy', 'Docker', 'Vercel'],
    glow: 'rgba(239, 68, 68, 0.15)', // Crimson Red
  },
  {
    title: 'AI Hotel Information Assistant',
    role: 'Backend AI Engineering',
    desc: 'Flask backend for document uploading and FAISS vector search — RAG-based Q&A over hotel documents. Containerized with Docker and deployed to production on AWS EC2.',
    tags: ['Flask', 'FAISS', 'AWS EC2', 'Docker'],
    glow: 'rgba(239, 68, 68, 0.15)', // Crimson Red
  },
  {
    title: 'MathsPrep AI',
    role: 'FYP — RAG Pipeline',
    desc: 'RAG-based math quiz generator from academic PDFs. Covers PDF ingestion, vector search (Chroma/FAISS), LLM integration for question generation, and a full Flutter mobile app for quiz-taking.',
    tags: ['LangChain', 'RAG', 'Flutter', 'Gemini', 'Python'],
    glow: 'rgba(239, 68, 68, 0.15)', // Crimson Red
  },
];

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.12 },
  },
};

const item = {
  hidden: { opacity: 0, y: 35 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6, ease: [0.25, 0.1, 0.25, 1] },
  },
};

function ProjectCard({ project }: { project: typeof projects[0] }) {
  const x = useMotionValue(0.5);
  const y = useMotionValue(0.5);

  // Smooth rotation angles mapped to mouse positions
  const rotateX = useSpring(useTransform(y, [0, 1], [15, -15]), { stiffness: 150, damping: 20 });
  const rotateY = useSpring(useTransform(x, [0, 1], [-15, 15]), { stiffness: 150, damping: 20 });

  function handleMouseMove(event: MouseEvent<HTMLDivElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    const mouseX = event.clientX - rect.left;
    const mouseY = event.clientY - rect.top;

    x.set(mouseX / width);
    y.set(mouseY / height);
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
        style={{
          rotateX,
          rotateY,
          transformStyle: 'preserve-3d',
        }}
        className="group relative overflow-hidden rounded-2xl border border-white/[0.06] bg-white/[0.01] p-6 sm:p-8 backdrop-blur-md transition-all duration-350 hover:border-[#ef4444]/35 hover:shadow-[0_0_40px_rgba(239,68,68,0.08)] cursor-pointer"
      >
        {/* Glow follow effect */}
        <div className="pointer-events-none absolute inset-0 rounded-2xl opacity-0 transition-opacity duration-300 group-hover:opacity-100 bg-[radial-gradient(350px_circle_at_var(--mouse-x,50%)_var(--mouse-y,50%),rgba(239,68,68,0.08),transparent_80%)]" />

        {/* 3D Floating Glowing Orb Backdrop */}
        <div
          className="absolute -right-8 -bottom-8 w-32 h-32 rounded-full bg-[#ef4444] opacity-5 filter blur-2xl transition-all duration-500 group-hover:opacity-20 group-hover:scale-125"
          style={{ transform: 'translateZ(10px)' }}
        />

        {/* Header line highlight */}
        <div className="absolute top-0 left-0 right-0 h-[1.5px] bg-gradient-to-r from-transparent via-[#ef4444]/20 to-transparent" />

        {/* Layered Content */}
        <div className="relative z-10 flex flex-col h-full justify-between" style={{ transform: 'translateZ(30px)', transformStyle: 'preserve-3d' }}>
          <div>
            <div className="flex items-center justify-between mb-5" style={{ transform: 'translateZ(25px)' }}>
              <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#ef4444]">
                {project.role}
              </span>
              <span className="text-white/20 transition-all duration-300 group-hover:translate-x-1 group-hover:-translate-y-1 group-hover:text-[#ef4444]">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                </svg>
              </span>
            </div>
            
            <h3 
              className="mb-4 text-2xl font-black tracking-tight text-white uppercase sm:text-3xl"
              style={{ transform: 'translateZ(45px)' }}
            >
              {project.title}
            </h3>
            
            <p 
              className="mb-8 text-xs sm:text-sm leading-relaxed text-white/50 group-hover:text-white/60 transition-colors duration-300"
              style={{ transform: 'translateZ(35px)' }}
            >
              {project.desc}
            </p>
          </div>

          <div className="flex flex-wrap gap-1.5 mt-auto" style={{ transform: 'translateZ(40px)' }}>
            {project.tags.map((t) => (
              <span
                key={t}
                className="rounded-md border border-[#ef4444]/20 bg-[#ef4444]/5 px-2.5 py-0.5 text-[10px] font-bold tracking-wider text-[#ef4444]/90 uppercase transition-all duration-300 group-hover:border-[#ef4444]/40"
              >
                {t}
              </span>
            ))}
          </div>
        </div>
      </motion.div>
    </div>
  );
}

export default function Projects() {
  return (
    <section
      id="projects"
      className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24"
    >
      {/* Subtle top line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="relative mb-16">
          <motion.p
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]"
          >
            Selected Work
          </motion.p>
          <motion.h2
            initial={{ opacity: 0, y: 15 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-100px' }}
            className="text-3xl font-black tracking-tight sm:text-4xl text-white uppercase"
          >
            Projects
          </motion.h2>
          <div className="absolute -bottom-4 left-0 w-12 h-[2.5px] bg-[#ef4444]" />
        </div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: '-50px' }}
          className="grid gap-6 sm:grid-cols-2"
        >
          {projects.map((p) => (
            <ProjectCard key={p.title} project={p} />
          ))}
        </motion.div>
      </div>
    </section>
  );
}
