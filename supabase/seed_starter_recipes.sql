-- ============================================================
-- Starter recipe pool — 25 curated recipes (curated 2026-07)
-- Re-runnable: existing rows are skipped. Run the WHOLE file.
-- ============================================================

-- Statement 1: the recipes themselves
insert into public.recipes (title, source_url, platform)
values
  ('Garlic Butter Pasta',        'https://www.tiktok.com/t/ZP8GTuReP/', 'tiktok'),
  ('Creamy Tomato Pasta',        'https://www.tiktok.com/t/ZP8GTBgDQ/', 'tiktok'),
  ('Chicken Parm Sandwich',      'https://www.tiktok.com/t/ZP8GTktFf/', 'tiktok'),
  ('Quesadillas',                'https://www.tiktok.com/t/ZP8GTBYGR/', 'tiktok'),
  ('Ground Beef Tacos',          'https://www.tiktok.com/t/ZP8GTfA7D/', 'tiktok'),
  ('Chicken Burrito Bowl',       'https://www.tiktok.com/t/ZP8GTYw2S/', 'tiktok'),
  ('Onigiri',                    'https://www.tiktok.com/t/ZP8GT6QaQ/', 'tiktok'),
  ('Chicken Katsu',              'https://www.tiktok.com/t/ZP8GTxKF8/', 'tiktok'),
  ('Oyakodon',                   'https://www.tiktok.com/t/ZP8GTHMkT/', 'tiktok'),
  ('Kimchi Fried Rice',          'https://www.tiktok.com/t/ZP8GTxVFE/', 'tiktok'),
  ('Kimchi Jjigae',              'https://www.tiktok.com/@franziee_v/video/7069319881233075483', 'tiktok'),
  ('Korean Corn Dogs',           'https://www.tiktok.com/@gisellecooks_/video/7605019040607653134', 'tiktok'),
  ('Pad See Ew',                 'https://www.tiktok.com/@derekkchen/video/7383002445821087018', 'tiktok'),
  ('Thai Basil Chicken',         'https://www.tiktok.com/@bakeandcookmommysally/photo/7651303919016054024', 'tiktok'),
  ('Chicken Adobo',              'https://www.tiktok.com/@cassyeungmoney/video/7620578033501572382', 'tiktok'),
  ('Garlic Fried Rice + Egg',    'https://www.tiktok.com/@derekkchen/video/7216377222356061482', 'tiktok'),
  ('Butter Chicken',             'https://www.tiktok.com/@erin.lim/video/7535466134028438797', 'tiktok'),
  ('Chana Masala',               'https://www.tiktok.com/@nutrientmatters/video/7361133374171352326', 'tiktok'),
  ('Smash Burgers',              'https://www.tiktok.com/@thegoldenbalance/video/7635720914893622541', 'tiktok'),
  ('Mac and Cheese',             'https://www.tiktok.com/@biteswithesther/video/7436569145677778218', 'tiktok'),
  ('Sheet-Pan Chicken & Veggies','https://www.tiktok.com/@recipeincaption/video/7650621062496931079', 'tiktok'),
  ('Egg Fried Rice',             'https://www.tiktok.com/@christieathome/video/7449794444385111302', 'tiktok'),
  ('Mongolian Beef',             'https://www.tiktok.com/@platedbyjordan/video/7655584544074091790', 'tiktok'),
  ('Chicken Gyro Bowl',          'https://www.tiktok.com/@elliemaehunn/photo/7481660848868461846', 'tiktok'),
  ('Shakshuka',                  'https://www.tiktok.com/@thegoldenbalance/video/7384112645508582702', 'tiktok')
on conflict (source_url) do nothing;

-- Statement 2: starter tags (cuisines + time), joined by title
insert into public.starter_recipes (recipe_id, cuisines, time_bracket)
select r.id, p.cuisines, p.time_bracket
from (values
  ('Garlic Butter Pasta',         array['italian']::text[],            'under_20'),
  ('Creamy Tomato Pasta',         array['italian'],                    '20_to_45'),
  ('Chicken Parm Sandwich',       array['italian','american'],         '20_to_45'),
  ('Quesadillas',                 array['mexican'],                    'under_20'),
  ('Ground Beef Tacos',           array['mexican'],                    'under_20'),
  ('Chicken Burrito Bowl',        array['mexican'],                    '20_to_45'),
  ('Onigiri',                     array['japanese'],                   'under_20'),
  ('Chicken Katsu',               array['japanese'],                   '20_to_45'),
  ('Oyakodon',                    array['japanese'],                   '20_to_45'),
  ('Kimchi Fried Rice',           array['korean'],                     'under_20'),
  ('Kimchi Jjigae',               array['korean'],                     '20_to_45'),
  ('Korean Corn Dogs',            array['korean'],                     'over_45'),
  ('Pad See Ew',                  array['thai'],                       '20_to_45'),
  ('Thai Basil Chicken',          array['thai'],                       'under_20'),
  ('Chicken Adobo',               array['filipino'],                   '20_to_45'),
  ('Garlic Fried Rice + Egg',     array['filipino'],                   'under_20'),
  ('Butter Chicken',              array['indian'],                     '20_to_45'),
  ('Chana Masala',                array['indian'],                     '20_to_45'),
  ('Smash Burgers',               array['american'],                   'under_20'),
  ('Mac and Cheese',              array['american'],                   '20_to_45'),
  ('Sheet-Pan Chicken & Veggies', array['american'],                   '20_to_45'),
  ('Egg Fried Rice',              array['chinese'],                    'under_20'),
  ('Mongolian Beef',              array['chinese'],                    '20_to_45'),
  ('Chicken Gyro Bowl',           array['mediterranean'],              '20_to_45'),
  ('Shakshuka',                   array['mediterranean'],              '20_to_45')
) as p(title, cuisines, time_bracket)
join public.recipes r on r.title = p.title
on conflict (recipe_id) do nothing;
