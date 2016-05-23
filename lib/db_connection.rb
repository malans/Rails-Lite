require 'sqlite3'
require 'byebug'
# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
ROOT_FOLDER = File.join(File.dirname(__FILE__), '..')
SQL_FILE = File.join(ROOT_FOLDER, 'db/users.sql')
DB_FILE = File.join(ROOT_FOLDER, 'db/users.db')

# SQL_FILE = Dir['./db/*.sql'].first
DB_FILES = Dir['./db/*.db'].first

# if DB_FILE.nil?

class DBConnection
  def self.open(db_file_name)
    # save a reference to the SQLite3::Database object
    # so we can execute SQL commands on it
    @db = SQLite3::Database.open(db_file_name)
    @db.results_as_hash = true
    @db.type_translation = true

    @db
  end

  # erase the sqlite3 db file and make a new one using commands in the sql file
  def self.reset
    if DB_FILES.empty?
      # redirect output of sql file to sqlite3 db file using a pipe
      commands = [
        # "rm '#{DB_FILE}'",
        "cat '#{SQL_FILE}' | sqlite3 '#{DB_FILE}'"
      ]

      commands.each { |command| `#{command}` }  # Kernel#` for executing shell commands
    end
    DBConnection.open(DB_FILE)
  end

  def self.instance
    reset if @db.nil?

    @db
  end

  def self.execute(*args)
    # Executes the given SQL statement. If additional parameters are given,
    # they are treated as bind variables, and are bound to the placeholders
    # in the query
    puts args[0]

    instance.execute(*args)
  end

  def self.execute2(*args)
    # Executes the given SQL statement, exactly as with #execute. However,
    # the first row returned (either via the block, or in the returned array)
    # is always the names of the columns. Subsequent rows correspond to the data
    # from the result set.
    # Thus, even if the query itself returns no rows, this method will always
    # return at least one row–the names of the columns.
    puts args[0]

    instance.execute2(*args)
  end

  def self.last_insert_row_id
    instance.last_insert_row_id
  end

end
