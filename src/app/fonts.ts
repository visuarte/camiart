import localFont from 'next/font/local';

/**
 * Fuentes servidas desde el repo (woff2 variables, subset latin, licencia OFL-1.1).
 *
 * POR QUÉ local y no `next/font/google`: el build de Vercel pedía el CSS a Google en cada
 * compilación y, cuando Google respondía con URLs sin extensión (`/l/font?kit=...`), el
 * loader de Next reventaba (`Cannot read properties of null (reading '1')`). Fallaba ~50%
 * de los builds (medido 23 nov 2026, 4 de 8). Con las fuentes en el repo el build no sale a la red.
 *
 * Los ficheros están en `src/app/fonts/`. Ver `LICENSES.md` de esa carpeta.
 */

export const manrope = localFont({
  src: './fonts/Manrope-latin-var.woff2',
  weight: '200 800',
  style: 'normal',
  display: 'swap',
  variable: '--font-sans',
});

export const spaceGrotesk = localFont({
  src: './fonts/SpaceGrotesk-latin-var.woff2',
  weight: '300 700',
  style: 'normal',
  display: 'swap',
  variable: '--font-display',
});

export const montserrat = localFont({
  src: './fonts/Montserrat-latin-var.woff2',
  weight: '100 900',
  style: 'normal',
  display: 'swap',
  variable: '--font-montserrat',
});

export const inter = localFont({
  src: './fonts/Inter-latin-var.woff2',
  weight: '100 900',
  style: 'normal',
  display: 'swap',
  variable: '--font-inter',
});
