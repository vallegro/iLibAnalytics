#!/usr/bin/env ruby

require 'rubygems'
require 'mysql'

begin 
  con=Mysql.new 'localhost', 'UR SQL USER', 'PASSWD'
  puts con.get_server_info
  con.select_db('irec')
  con.query("SET character_set_server = utf8;")
  ts = con.query "show tables"
  t_rows = ts.num_rows
  t_rows.times do 
    puts ts.fetch_row
  end
rescue Mysql::Error =>e
  puts e.errno
  puts e.error
end


depth = 0
inlist = false
intrack = false
tb_name = "default"
tid = 0
tidind = false
name = "defaut"
nameind = false
count = -1
countind =false


file = File.open('iTunes Music Library.xml',"r")
data = file.read
data.each_line do |line|
  
  if pos = line=~/<dict>/
    depth = depth+1
  elsif pos = line=~/<\/dict>/
    depth =depth-1
  end
  
  
  if depth==1
  
    if inlist
      inlist = false
      break
    elsif datem = line.match(/(<date>)(\d+)-(\d+)-(\d+)(T.*?Z)(<\/date>)/)
      d1,year,month,day,d2,d3 = datem.captures
      tb_name = "tl#{year}#{month}#{day}"
      createtb="create table #{tb_name} (tid  BIGINT UNSIGNED, name varchar(255) character set utf8, count int) default charset=utf8;"
      begin
        con.query(createtb)
      rescue Mysql::Error =>e
        puts e.errno
        puts e.error
        if e.errno ==1050
          boolcon=true
          puts "rescan?"
          while boolcon
            puts  "y/n "
            line=gets
            puts line
            if line == "y\n"
              droptb="drop table " << tb_name
              puts droptb
              con.query(droptb)
              createtb="create table #{tb_name} (tid BIGINT UNSIGNED, name varchar(255) character set utf8, count int) default charset=utf8;"
              con.query(createtb)
              boolcon=false
            elsif line == "n\n"
              puts "exiting"
              exit
            end
          end
        end
      end
      puts " #{tb_name} created "     
    end
 
  elsif depth==2
  
    if inlist==false
      inlist = true
    elsif intrack==true
      insert_track = "insert into #{tb_name} values (#{tid},\"#{name}\",#{count});"
      # puts insert_track
      con.query(insert_track)
      intrack = false
      tidind = false
      nameind = false
      countind = false
      #  puts "one track", the scanning of a track finished
      if tidind&&nameind&&countind !=true
        puts "Caution: incomplete Track info"
      end
    end
 
  elsif depth==3
    
    if inlist
      intrack = true
    else
      puts "Caution: depth3 outside of Track list"
    end
    
    if (!tidind) && tidm = line.match(/(<key>Persistent ID<\/key><string>)(.*?)(<\/string>)/)
      t1,tid,t2=tidm.captures
      puts "tid#{tid}"
      tid= tid.to_i(16)
      puts tid
      tidind = true
    elsif (!nameind) && namem = line.match(/(<key>Name<\/key><string>)(.*?)(<\/string>)/)
      n1,name,n2=namem.captures
      name=name.gsub("\"","\\\"")
      #puts "name#{name}"
      nameind = true
    elsif (!countind) && countm = line.match(/(<key>Play Count<\/key><integer>)(\d+)(<\/integer>)/) 
      c1,count,c2 = countm.captures
      #puts "count#{count}"
      countind=true
      if countind==false
        count=0
        countind=true
      end
    end
  end
end

con.close if con

#tid = data.scan(  /<key>Track ID<\/key><integer>(\d+)<\/integer>/)
#count = data.scan(/<key>Play Count<\/key>/)
#puts tid.length
#puts name.length
#puts count.length

#name = line.match(/<key>Name<\/key><string>(.*?)<\/string>/)
#puts name
#end
