require 'rubygems'
require 'sqlite3'
require 'digest/sha1'

$dbfile = 'lilurl.db'

#makes a db and cleans it up, takes in a block with a single parameter which is the db
def usingDb(dbName)
    begin
            db = SQLite3::Database.open dbName
            yield db
        rescue SQLite3::Exception => e
            puts "an error occurred: " + e
        ensure
            db.close if db
    end
end

#makes a statement and cleans it up, takes in a block with a single parameter which is the statement
#should be nested in the above usingdb
#currently unused
def usingStatement(db,sql)
    begin
        statement = db.prepare sql
        if block_given?
            yield statement
        else
            statement.execute
        end

        ensure
            statement.close if statement
    end
end

def geturl(hash)
  usingDb($dbfile) do |db|
      row = db.get_first_row("SELECT url FROM urls WHERE hash = ?", hash)
          if !row.nil?
              return row.join "\s"
          else
            raise ArgumentError.new("Hash: #{hash} was not found to map to anything")
          end
        end
end

def makeurl(oldurl, postfix = nil)
  # error check oldurl
  if !(oldurl =~ %r"^https?://") or oldurl.nil?
    raise ArgumentError.new('Please submit a valid HTTP URL.')
  end

  #prep hash
  if !postfix.empty?
    if postfix.length > 20
      raise ArgumentError.new('Your postfix must be 20 characters or less.')
    end
    hash = postfix
  else
    hash = Digest::SHA1.hexdigest oldurl
    hash = hash[0..5]
  end

  usingDb($dbfile) do |db|
      db.execute("CREATE TABLE IF NOT EXISTS urls(hash varchar(20) primary key, url varchar(300))")
      #check and see if the hash is unique
      row = db.get_first_row("SELECT hash FROM urls WHERE hash = ?",hash)
      if !row.nil? 
              # column hash is not unique
              # 1) URL already exists in the database and will hash to the same index
              # 2) someone already tried to use that postfix
          if !postfix.empty?
              raise ArgumentError.new('That postfix has already been taken. Please use a different one or let me generate one.')
          else
            #repeat url
            return hash
          end
      end
      #hash is unique, insert
      db.execute("INSERT INTO urls VALUES (?,?)", hash, oldurl)
      return hash
  end
end
