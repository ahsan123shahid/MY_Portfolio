'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useScroll, useMotionValueEvent } from 'framer-motion';

const FRAME_COUNT = 200;

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
      // Set the resolution of the backing store
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      // Set the visual size
      canvas.style.width = `${window.innerWidth}px`;
      canvas.style.height = `${window.innerHeight}px`;
      
      // We draw directly into the backing store coordinates (cw, ch) in renderFrame.
      // Do NOT apply ctx.scale(dpr, dpr) here because we are calculating the drawing
      // sizes based on the backing store canvas width/height (which already incorporates dpr).
      renderFrame(currentFrameRef.current);
    };

    resize();
    window.addEventListener('resize', resize);

    const loadImages = async () => {
      // 1. Load the first frame immediately so the canvas is not blank
      const firstImg = new Image();
      firstImg.src = `/sequence/frame_000_delay-0.05s.webp`;
      await new Promise<void>((resolve) => {
        firstImg.onload = () => resolve();
        firstImg.onerror = () => resolve();
      });
      imagesRef.current[0] = firstImg;
      renderFrame(0);

      // 2. Load the rest of the frames in small batches in the background
      const batchSize = 8;
      for (let i = 1; i < FRAME_COUNT; i += batchSize) {
        const promises = [];
        for (let j = 0; j < batchSize && (i + j) < FRAME_COUNT; j++) {
          const index = i + j;
          const pad = String(index).padStart(3, '0');
          const img = new Image();
          const p = new Promise<void>((resolve) => {
            img.onload = () => {
              imagesRef.current[index] = img;
              // If the scroll position has moved or is currently here, re-render
              if (currentFrameRef.current === index) {
                renderFrame(index);
              }
              resolve();
            };
            img.onerror = () => resolve();
            img.src = `/sequence/frame_${pad}_delay-0.05s.webp`;
          });
          promises.push(p);
        }
        await Promise.all(promises);
      }
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
      className="absolute inset-0 block"
      style={{ objectFit: 'cover' }}
    />
  );
}
