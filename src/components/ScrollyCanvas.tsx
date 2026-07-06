'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useScroll, useMotionValueEvent } from 'framer-motion';

const FRAME_COUNT = 200;
const BASE_PATH = process.env.NODE_ENV === 'production' ? '/MY_Portfolio' : '';

export default function ScrollyCanvas({ containerRef }: { containerRef?: React.RefObject<HTMLDivElement> }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const imagesRef = useRef<HTMLImageElement[]>([]);
  const currentFrameRef = useRef(0);
  const rafRef = useRef(0);
  
  const { scrollYProgress } = useScroll(
    containerRef
      ? { target: containerRef as any, offset: ['start start', 'end end'] }
      : undefined
  );

  const getClosestLoadedIndex = useCallback((index: number) => {
    if (imagesRef.current[index]) return index;
    let step = 1;
    while (index - step >= 0 || index + step < FRAME_COUNT) {
      if (index - step >= 0 && imagesRef.current[index - step]) return index - step;
      if (index + step < FRAME_COUNT && imagesRef.current[index + step]) return index + step;
      step++;
    }
    return -1;
  }, []);

  const renderFrame = useCallback((index: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const loadedIndex = getClosestLoadedIndex(index);
    if (loadedIndex === -1) return;
    
    const img = imagesRef.current[loadedIndex];
    if (!img) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const { width: cw, height: ch } = canvas;
    const { naturalWidth: iw, naturalHeight: ih } = img;

    const scale = Math.max(cw / iw, ch / ih);
    const sw = iw * scale;
    const sh = ih * scale;
    const sx = (cw - sw) / 2;
    const sy = (ch - sh) / 2;

    ctx.clearRect(0, 0, cw, ch);
    ctx.drawImage(img, sx, sy, sw, sh);
  }, [getClosestLoadedIndex]);

  useMotionValueEvent(scrollYProgress, 'change', (v) => {
    const index = Math.min(
      Math.max(Math.round(v * (FRAME_COUNT - 1)), 0),
      FRAME_COUNT - 1
    );
    if (index === currentFrameRef.current) return;
    currentFrameRef.current = index;
    cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(() => renderFrame(index));
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const resize = () => {
      const dpr = window.devicePixelRatio || 1;
      // Set the backing store resolution directly to window dimensions
      // to avoid 300x150 default size on initial mount before layout completes
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;

      renderFrame(currentFrameRef.current);
    };

    resize();
    window.addEventListener('resize', resize);

    const loadImages = () => {
      // 1. Load the first frame immediately so the canvas is not blank
      const firstImg = new Image();
      firstImg.onload = () => {
        imagesRef.current[0] = firstImg;
        renderFrame(0);

        // 2. Once first frame is active, stream all other frames concurrently
        for (let i = 1; i < FRAME_COUNT; i++) {
          const index = i;
          const pad = String(index).padStart(3, '0');
          const img = new Image();
          img.onload = () => {
            imagesRef.current[index] = img;
            // If the user has scrolled to this frame, render it immediately
            if (currentFrameRef.current === index) {
              renderFrame(index);
            }
          };
          img.src = `${BASE_PATH}/sequence/frame_${pad}_delay-0.05s.webp`;
        }
      };
      firstImg.onerror = () => {
        // Fallback: trigger background loads even if first frame failed
        for (let i = 1; i < FRAME_COUNT; i++) {
          const index = i;
          const pad = String(index).padStart(3, '0');
          const img = new Image();
          img.onload = () => {
            imagesRef.current[index] = img;
            if (currentFrameRef.current === index) {
              renderFrame(index);
            }
          };
          img.src = `${BASE_PATH}/sequence/frame_${pad}_delay-0.05s.webp`;
        }
      };
      firstImg.src = `${BASE_PATH}/sequence/frame_000_delay-0.05s.webp`;
    };

    loadImages();

    return () => {
      window.removeEventListener('resize', resize);
      cancelAnimationFrame(rafRef.current);
    };
  }, [renderFrame]);

  return (
    <canvas
      ref={canvasRef}
      className="absolute inset-0 w-full h-full block"
    />
  );
}
