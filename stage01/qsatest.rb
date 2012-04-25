#!/usr/bin/ruby
# Author: Neil Soman <neil@eucalyptus.com>

require 'rubygems'
require 'right_aws'
require 'time'
require 'base64'
require 'cgi'
require 'openssl'
require 'digest/sha1'
require 'uri'
require 'net/http'

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
    log_success("Adding object: %s" % objectname)
    return key
end

def delete_object(key)
    if key.delete
	log_success("Object %s deleted" % key.name)
    else
	log_failure("Unable to delete object %s" % key.name)
    end
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

def setup_s3(access_key, secret_key)
    s3 = RightAws::S3.new(access_key, secret_key) 
end

def screen_dump(string)
    log_success("******%s******" % string)
end

def make_url(verb, bucket, key, s3_url, access_key, secret_key)
    expires = Time.now.to_i + 86400
    string_to_sign = verb + "\n\n\n%s" % expires + "\n/services/Walrus/" + bucket + "/" + key;
    hmac = CGI::escape(Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_key, string_to_sign)).strip)
    return s3_url + "/" + bucket + "/" + key + "?AWSAccessKeyId=" + access_key + "&Expires=%s" % expires + "&Signature=" + hmac
end

def test0(s3, s3_url, access_key, secret_key)
begin
    bucket_name = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucket_name, true, 'public-read', :location => :us)
    object_name = 'test_object_%s' % generate_string(10)
    object = put_object(bucket, object_name)
    url = make_url('GET', bucket_name, object_name, s3_url, access_key, secret_key)
    uri = URI.parse(url)
    begin
        data = Net::HTTP.get(uri)
	if data.include? '403'
	    log_failure('test0 failed %s' % data)
	end
        log_success(data)
    rescue Net::HTTPServerException
	log_failure("Unable to issue request. test0 failed.")
    end
    delete_object(object)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test0 failed")
end
end

access_key = ENV['EC2_ACCESS_KEY']
secret_key = ENV['EC2_SECRET_KEY']
s3_url = ENV['S3_URL']
s3 = setup_s3(access_key, secret_key)

if not access_key
    log_failure("EC2_ACCESS_KEY must be set")
end

if not secret_key
    log_failure("EC2_SECRET_KEY must be set")
end

if not s3_url
    log_failure("S3_URL must be set")
end


test0(s3, s3_url, access_key, secret_key)
