require 'rubygems'
require 'sqlite3'
require 'digest/sha1'

$dbfile = 'lilurl.db'

def usingDb(dbName)
        db = SQLite3::Database.open dbName
        yield db
    ensure
        db.close if urldb
end

def usingStatement(db,sql)
  #ensure table exists
  usingStatement(db, "CREATE TABLE IF NOT EXISTS urls(hash varchar(20) primary key, url varchar(300))") 
        statement = db.prepare sql
    if block_given?
        yield statement
    else
        statement execute
    end
    ensure
        statement.close
end

def geturl(hash)
  usingDb($dbfile) do |db|
      usingStatement(db,"SELECT url FROM urls WHERE hash = ?") do |statement|
          row = statement get_first_row hash
          if !row.nil?
              return row.join "\s"
          else
            return "/"
          end
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
      #check and see if the hash is unique
      usingStatement(db, "SELECT hash FROM urls WHERE hash = ?") do |statement| 
          # column hash is not unique
          # 1) URL already exists in the database and will hash to the same index
          # 2) someone already tried to use that postfix
          row = statement get_first_row hash 
          if !row.nil? and !postfix.empty?
              raise ArgumentError.new('That postfix has already been taken. Please use a different one or let me generate one.')
          else
            return hash
          end
      end

      #hash is unique, insert
      usingStatement(db, "INSERT INTO urls VALUES (?,?)") do |statement|
        response = statement.execute hash, oldurl
         return hash
      end
  end
end
