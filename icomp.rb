#!/usr/bin/env ruby

require 'rubygems'
require 'mysql'

limit=25

begin
  con=Mysql.new 'localhost', 'local_database_user', 'passwd'
  puts con.get_server_info
  con.select_db('irec')
  con.query("set character_set_server = utf8;")
  tbls=con.query("select table_name from information_schema.tables where table_schema='irec' and table_type='base table';")
  nrows = tbls.num_rows
  rowp = nrows-1
  tblp=con.query("select table_name from INFORMATION_SCHEMA.TABLES where table_schema= 'irec' limit 1 OFFSET #{nrows-2}").fetch_row[0]
  tblc=con.query("select table_name from INFORMATION_SCHEMA.TABLES where table_schema= 'irec' limit 1 OFFSET #{nrows-1}").fetch_row[0]
  puts "tblp "<< tblp
  puts "tblc "<< tblc
  view_namev="v"<< tblc
  join="create view #{view_namev} (tid, name, count) as  select tblc.tid,tblc.name, tblc.count-tblp.count as count from #{tblp} as tblp join #{tblc} as tblc on tblp.tid=tblc.tid;"
 # puts join
  con.query(join)
  view_namesub="sub"<< tblc
  sub="create view #{view_namesub} (tid, name, count ) as select tblc.tid, tblc.name, tblc.count from #{tblc} as tblc  left join #{tblp} as tblp on tblc.tid=tblp.tid where tblp.tid=NULL"
  puts sub
  con.query(sub)
  union="(select * from #{view_namev}) union (select * from #{view_namesub}) order by count limit 10;"
  res=con.query(union)
  res.num_rows.times do
    puts res.fetch_row
  end

rescue Mysql::Error =>e
  puts e.errno
  puts e.error
ensure 
  con.close if con
end
