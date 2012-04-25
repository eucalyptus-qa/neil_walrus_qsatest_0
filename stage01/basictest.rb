#!/usr/bin/ruby
#Author: Neil Soman <neil@eucalyptus.com>

require 'rubygems'
require 'right_aws'

def log_success(message)
    puts "[TEST_REPORT]\t" + message
end

def log_failure(message)
    puts "[TEST_REPORT]\tFAILED: " + message
    exit(1)
end

def generate_string( len )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    generate_string = ""
    1.upto(len) { |i| generate_string << chars[rand(chars.size-1)] }
    return generate_string
end

def make_bucket(connection, bucketname, create)
begin
    return RightAws::S3::Bucket.create(connection, 'test_bucket_%s' % generate_string(10), create)
rescue RightAws::AwsError
    log_failure("Error creating bucket %s" % bucketname)
end
end

def put_object(bucket, objectname) 
    key = RightAws::S3::Key.create(bucket, objectname)
    key.data = 'werignrewngorwengiwrenginerwignioerwngirwengvndfrsignoreihgioerqngoirengoinianroignoignriaongr2202fg3q4gwng'
    key.put 
    return key
end

def get_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.get
    log_success("Last Modified: %s" % key.last_modified + "Owner: %s" % key.owner + "Size: %s" % key.size)
end

def delete_object(key)
    if key.delete
	log_success("Object %s deleted" % key.name)
    else
	log_failure("Unable to delete object %s" % key.name)
    end
end

def show_buckets(connection)
    my_buckets_names = connection.buckets.map{|b| b.name}
    puts my_buckets_names
end

def delete_bucket(bucket)
begin
    if bucket.delete(true)
        log_success("Bucket %s deleted" % bucket.name)
    else
	log.success("Unable to delete bucket: %s" % bucket.name)
    end
rescue RightAws::AwsError
    log_failure("Error creating bucket %s" % bucketname)
end
end

def setup_ec2
    return RightAws::Ec2.new(ENV['EC2_ACCESS_KEY'],ENV['EC2_SECRET_KEY'])
end

def setup_s3
    s3 = RightAws::S3.new(aws_access_key_id=ENV['EC2_ACCESS_KEY'], aws_secret_access_key=ENV['EC2_SECRET_KEY'])
end

def screen_dump(string)
    log_success("******%s******" % string)
end

def test0(s3)
    screen_dump('Object Put')
    bucket = make_bucket(s3, 'test_bucket_1', true)
    object = put_object(bucket, 'test_object_1')
    get_object(bucket, 'test_object_1')
    delete_object(object)
    delete_bucket(bucket)
end 

def test2(s3)
begin
    screen_dump('Bucket Location')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'public-read', :location => :us)
    log_success("Location %s" % bucket.location)
    object = put_object(bucket, 'test_object_2')
    get_object(bucket, 'test_object_2')
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test2 failed")
end
end

def test3(s3)
begin
    screen_dump('Object Copy')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'public-read', :location => :us)
    object = put_object(bucket, 'test_object31')
    object2 = RightAws::S3::Key.create(bucket, 'test_object4')
    object.copy(object2)
    if not object2.exists?
        log_failure("Object copy failed")
    end
    delete_object(object)
    delete_object(object2)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test3 failed")
end
end

def test4(s3)
begin
    screen_dump('Get Object ACL')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'public-read', :location => :us)
    object = put_object(bucket, 'test_object4')
    grantees = object.grantees
    for grantee in grantees
	log_success("Id: %s" % grantee.id + " Name: %s" % grantee.name + " Perms: %s" % grantee.perms)
    	end
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test4 failed")
end
end

def test5(s3)
begin
    screen_dump('Object rename')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'private', :location => :eu)
    object = put_object(bucket, 'test_object1')
    object.rename('test_object2')
    log_success('New name: %s' % object.name)
    if not object.exists?
        log_failure("Object rename failed")
    end
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test5 failed")
end
end

def test6(s3)
begin
    screen_dump('Object Move')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'public-read', :location => :us)
    object = put_object(bucket, 'test_object3')
    object2 = RightAws::S3::Key.create(bucket, 'test_object4')
    object.move(object2)
    if not object2.exists?
        raise "Object move failed"
    end
    if object.exists?
	raise "Object move failed"
    end
    delete_object(object2)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test6 failed")
end
end

def test7(s3)
begin
    screen_dump('Get Object Metadata')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'private', :location => :eu)
    object = RightAws::S3::Key.create(bucket, 'test_object1', data='testing hi there', meta_headers = {"group"=>"mygroup", "life"=>"mylife"})
    object.put
    if not object.exists?
        log_failure("Object creation failed")
    end
    log_success("%s" % object.reload_meta)
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test7 failed")
end
end

def test8(s3)
begin
    screen_dump('Modify Object Metadata')
    bucket = RightAws::S3::Bucket.create(s3,'test_bucket_%s' % generate_string(10), true, 'private', :location => :eu)
    object = RightAws::S3::Key.create(bucket, 'test_object1', data='testing hi there', meta_headers = {"group"=>"mygroup", "life"=>"mylife"})
    object.put
    if not object.exists?
        log_failure("Object creation failed")
    end
    log_success("%s" % object.reload_meta)
    object.save_meta(meta_headers = {"group"=>"yourgroup", "life"=>"isawesome"})
    log_success("%s" % object.reload_meta)
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test8")
end
end

s3 = setup_s3
test0(s3)
test2(s3)
test3(s3)
test4(s3)
test5(s3)
test6(s3)
test7(s3)
test8(s3)
