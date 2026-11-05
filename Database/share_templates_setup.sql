-- Hilo: share_templates setup
-- Ejecutar en Supabase SQL Editor.
-- Las imágenes se suben después al bucket "share-templates" usando las rutas
-- indicadas en image_path.

begin;

-- ------------------------------------------------------------
-- 1. Catálogo de plantillas
-- ------------------------------------------------------------

create unique index if not exists share_templates_name_key
    on public.share_templates (name);

alter table public.share_templates enable row level security;

drop policy if exists "Authenticated users can read share templates"
    on public.share_templates;

create policy "Authenticated users can read share templates"
    on public.share_templates
    for select
    to authenticated
    using (true);

-- ------------------------------------------------------------
-- 2. Storage para imágenes de plantillas
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('share-templates', 'share-templates', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Authenticated users can read share template images"
    on storage.objects;

create policy "Authenticated users can read share template images"
    on storage.objects
    for select
    to authenticated
    using (bucket_id = 'share-templates');

-- ------------------------------------------------------------
-- 3. Plantillas de color
-- ------------------------------------------------------------

insert into public.share_templates (name, config, is_default)
values
(
    'Book colors',
    '{
      "type": "cover_dynamic",
      "text_color": "#FFFFFF",
      "overlay_opacity": 0.20
    }'::jsonb,
    true
),
(
    'Warm paper',
    '{
      "type": "gradient",
      "colors": ["#EDE4D5", "#C7AD8D"],
      "start_point": "topLeading",
      "end_point": "bottomTrailing",
      "text_color": "#2B2925"
    }'::jsonb,
    false
),
(
    'Midnight',
    '{
      "type": "gradient",
      "colors": ["#141925", "#45304D"],
      "start_point": "topLeading",
      "end_point": "bottomTrailing",
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
),
(
    'Terracotta',
    '{
      "type": "gradient",
      "colors": ["#7A2E1F", "#C66A3D"],
      "start_point": "topLeading",
      "end_point": "bottomTrailing",
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
),
(
    'Ocean',
    '{
      "type": "gradient",
      "colors": ["#153F5B", "#43899D"],
      "start_point": "topLeading",
      "end_point": "bottomTrailing",
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
),
(
    'Sage',
    '{
      "type": "gradient",
      "colors": ["#354F45", "#7A9674"],
      "start_point": "topLeading",
      "end_point": "bottomTrailing",
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
)
on conflict (name) do update set
    config = excluded.config,
    is_default = excluded.is_default;

-- ------------------------------------------------------------
-- 4. Plantillas con imagen
-- ------------------------------------------------------------
-- Subir primero estos archivos al bucket share-templates:
--   images/quote-paper-01.jpg
--   images/quote-night-01.jpg
--
-- El bucket es público para que ImageRenderer/AsyncImage puedan leer las
-- imágenes mediante una URL estable. No se guardan binarios en PostgreSQL.

insert into public.share_templates (name, config, is_default)
values
(
    'Paper texture',
    '{
      "type": "image",
      "image_path": "images/quote-paper-01.jpg",
      "overlay_color": "#000000",
      "overlay_opacity": 0.16,
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
),
(
    'Night texture',
    '{
      "type": "image",
      "image_path": "images/quote-night-01.jpg",
      "overlay_color": "#000000",
      "overlay_opacity": 0.28,
      "text_color": "#FFFFFF"
    }'::jsonb,
    false
)
on conflict (name) do update set
    config = excluded.config,
    is_default = excluded.is_default;

commit;

-- ------------------------------------------------------------
-- 5. Plantilla elegida por cada cita
-- ------------------------------------------------------------

alter table public.quotes
    add column if not exists template_id integer
    references public.share_templates(id)
    on delete set null;

create index if not exists quotes_template_id_idx
    on public.quotes(template_id);

-- quote_shares queda opcional:
-- úsala solamente si quieres registrar analytics de compartir.
-- No es necesaria para guardar la plantilla seleccionada ni la imagen.
