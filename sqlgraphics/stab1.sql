/*

This code has been modified somewhat from the original to run in a 2010 era environment;
specifically, the CREATE PHANTOM MACHINE block has been eliminated since phantom machines
didn't really replace virtual machines until about 2016 and weren't fully supported by
SQL until ~2018.  Instead, we just run in the root environment and delete everything we 
care about upfront if it exists.

Also, optimizations for the SQPU (Structured Query Processing Unit, or Skup-you) have been
largely ignored, with translations hacked in where needed and other "optimization" left in
situ without comment, so that some of this code may appear as odd to a modern reader as it 
would have to a programmer from 2010.  

While this might offend purists, the fact is the harware available in those days was so 
pathetically underpowered and unreliable that the difference is hardly noticable.

*/

--
-- Make a clean start
--

drop table if exists face   cascade;
drop type  if exists color  cascade;
drop type  if exists spot   cascade;
drop type  if exists vector cascade;

--
-- Define our types, tables, and helper functions
--

-- COLOR:
create type color as (r real, g real, b real, a real);
create function the_color(real,real,real) returns color as 'select $1,$2,$3,$1-$1;' language sql;

-- FACE: A colored polygon at a given distance & tilted at a specified angle (all projected into view space)
create table face (id integer not null, perimeter polygon, c color, z0 real, zx real, zy real, primary key (id));
-- TODO: replace zx & zy with a true normal

-- VECTOR:
create type vector as (x real, y real, z real);
create function the_vector(real,real,real) returns vector as $$
    select $1,$2,$3;
    $$ language sql;
create function dot(vector,vector) returns real as $$
    select $1.x*$2.x + $1.y*$2.y + $1.z*$2.z;
    $$ language sql;

-- SPOT: A pixel's worth of color at a specified distance from and angle to the viewer
create type spot as (z real, c color, normal vector);
create function the_spot(real,color,vector) returns spot as 'select $1,$2,$3;' language sql;
create function color_of(spot) returns color as 'select $1.c;' language sql;

--
-- Set up the image to render; normally this would come from outside
--
-- TODO: Get real / interesting image data in here!
insert into face values (1, '( (-Infinity,-Infinity),(-Infinity,Infinity), (Infinity,Infinity), (Infinity,-Infinity) )',(0.0,0.0,0.0,1.0),10000,0.0,0.0);
insert into face values (2, '( ( 0.0 ,0.0 ),( 0.0,10.0 ), ( 10.0,10.0 ) )',(0.5,0.5,0.0,1.0),0.0,1.0,0.5);


--
-- How far back from the viewer is the spot where the pixel-ray intersects the polygon
--
create function depth_of_intersection(point,face) returns real as $$
    select cast($2.z0 + $2.zx*$1[0] + $2.zy*$1[1] as real);
    $$ language sql;

--
-- Accumulate colors as we walk the pixel-ray from back to front
--
-- TODO: use alpha and normal to blend, rather than just treating all spots as opaque/matte blobs
create function add_color(spot,spot) returns spot as $$
    select $2;
    $$ language sql;

create aggregate color_from  (
    basetype = spot,
    sfunc = add_color,
    stype = spot,
    finalfunc = color_of,
    initcond = '(Infinity,"(0.0,0.0,0.0,0.0)","(0.0,0.0,-1.0)")'
    );

--
-- Walk through all the pixels we need, accumulating the rgba values
--
/* Old version, 'cause I'm sentamental--or at least mental
select 
    p.x as x, 
    p.y as y, 
    color_from(the_spot(depth_of_intersection(point(p.x,p.y),f),f.c,the_vector(0.0,0.0,1.0))) as c 
  from 
    (select generate_series(1,5) as y,generate_series(1,7) as x) p left join 
  face f on f.perimeter ~ point(p.x,p.y)
  group by p.x,p.y
  order by p.x,p.y
  ;
*/

-- TODO: Wrap this in an agregator that makes it into a blob w. the image data
-- TODO: Un-embedd the height and width
-- TODO: Put normal on the face and propogate it

select 
    color_from(the_spot(z,c,the_vector(0.0,0.0,1.0))) as pixel 
  from 
(select 
    p.x as x, 
    p.y as y, 
    depth_of_intersection(point(p.x,p.y),f) as z,
    f.c as c
  from 
    (select generate_series(1,5) as y,generate_series(1,7) as x) p left join 
  face f on f.perimeter ~ point(p.x,p.y)
  order by y desc,x,z desc
) v
  group by y,x
  ;

