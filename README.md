# RackAsyncProxy

Proxies all requests to a service end-point of your choosing asynchronously
(Uses green threads)

Very naive implementation:

* Doesn't handle https requests to the end-point
* If parent process dies, RackAsyncProxy doesn't wait, it just kill it's threads.
* Has 30 second timeout limit for subrequests

## Installation

Add this line to your application's Gemfile:

    gem 'rack_async_proxy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_async_proxy

## Usage

Example Usage:

    use RackAsyncProxy do |req|
      if req.path =~ %r{^/remote/service.php$}
        URI.parse("http://remote-service-provider.com/service-end-point.php?#{req.query}")
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
