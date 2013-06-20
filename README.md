# Coca

Coca stands for **Chain of Command Authentication**. It's a lightweight authentication-delegation scheme that makes SSO very easy to add to a devise-based rails app. It works through an ordinary JSON API so you can pass any user data you like down the chain after authentication succeeds.

We thought about calling it 'delegated devise' because in the present implementation it's just a devise strategy that can delegate to another application and an API for receiving delegated auth calls. In future we'd like to extend the principle more widely so we gave it a more general name.

Coca is highly configurable but the defaults are simple and secure. It is designed to be part of a service-based architecture, where it will bind together a set of applications around a shared authentication service.

Coca is naturally extensible because you can send any information you like down the chain and do whatever you like when it arrives. RBAC or some other authorization scheme is very easy to add.

Coca also supports attribute propagation: your auth master is likely also to be a directory server and coca can automatically send notifications up and down the chain when attributes change. This allows you to offer a profile form on any application in the chain but hold the profile columns on only one (presumably but not necessarily the master).


## tl;dr

    class User < ActiveRecord::Base
      devise :cocable
    end
    
    # and in an initialiser:
    
    Coca.delegate_to do |master|
      master.host = localhost
      master.port = 8088
      master.secret = "key"
    end


## Compared to OAuth

* **This is not an authorization service.** There is no mechanism for issuing API tokens or granting access to individual resources. The chain of command is defined on initialisation and all requests and responses have to come from sources that are already trusted. OAuth makes it possible to have ad-hoc relationships between strangers. Coca is a conversation among friends.

* **OAuth is a user-pull scheme** that bounces off the browser a few times and requires it to pass callbacks between servers. The user sees confirmation dialogs from different providers or is forced to visit services in a certain order. Coca works by server-pull, invisible to the user and no more difficult than just logging in. It doesn't matter where you arrive: once you've logged in, you're in.

* **Oauth works across domains.** Coca mostly doesn't: you can authenticate against a master at any address, but SSO is limited to domains that can share a cookie. In practice that means coca only provides SSO across related subdomains.

* **OAuth is horrible to work with,** absurdly complicated and a daft way to implement SSO unless you are also piggybacking on a remote service. Coca is quite nice.


## Compared to XAuth

* XAuth is just OAuth made stupider. It is superficially similar to coca in that credentials are passed to a remote server, but after that you're bouncing around callbacks again. 


## Compared to LDAP

There's nothing wrong with LDAP. If you're working in a situation where an LDAP server is available, and you don't need to layer RBAC or anything else on top, we advise you to use it.

If you don't already have an LDAP server with its own availability regime and a dedicated team of lab-coats, you get to choose between several lardy Java services. None of them will sit nicely on your load-balanced cloud node, and none of them are easy to couple with RBAC or other services.


## Use coca if

* You want to implement single sign-on within a cluster of trusted applications that all live in a single domain;

* You want an easy way to pass around permissions or other extended user information;

* You want your authentication service to be part of your usual rails cluster and benefit from its existing availability and backup measures;

* You're not planning to offer a remote login-with-me service to applications as yet unknown.

There's nothing to stop you running coca in parallel with other auth services including OAuth, SAML or even LDAP.


## How it works

All the actual authentication done by devise as usual. Coca just adds a simple way to pass credentials up the chain and an auth token back down again.

#todo: perhaps the auth token is overcomplicated. it could just be an equivaltnt to the session cookie that we pass back.

1. A coca servant app has its own (typically devise-based) sign-in mechanism. You can set that up any way you like, and you can choose to accept credentials locally for some users.

2. If the app is presented with an auth token or login pair that it doesn't recognise, those credentials are passed up to the configured master application as a JSON request that includes a predefined API key. 

3. The master will check that the requesting host and the secret key match before it gives any response.

4. If the master application accepts the auth token or the username and password, it will return 200 and a package of user information. If the app doesn't recognise the credentials, it can pass them on to its own coca master. If there isn't one, or that request fails too, it will return 403 and no data. If it does receive approval from further up the chain, it is passed on down.

5. As the confirmation package travels down the chain each servant app stores the auth token and does what it likes with any other data that is returned.

6. Subsequent requests that present a valid auth token will be successful at the bottom of the chain.

7. The master will include in the confirmation package a configurable TTL for the auth token. You can use this to set a balance between revokability and responsiveness. Set it to zero for maximum control or to a sensible session length like 30 minutes to minimise the coca overhead.

8. The original servant app receives the confirmation package, saves the authentication token and does whatever it does with the other data. It also puts the auth token in a domain cookie (not the usual session cookie) that will be picked up by any other application in the same domain.

9. When the same browser visits another application in the same domain, it presents the master's auth token cookie. The second servant app passes that token up the chain to the same master. Having issued the token, the master accepts it and returns the same confirmation package as before. The second servant stores the auth token locally so that it too can accept subsequent requests without delegation, token expiry permitting.


## Usage

Each link in the chain of command is defined as a server to which we defer  and/or a set of servers from which we accept requests. Within that link you also have to declare that a particular model should take part in the authentication scheme.


### Configuring the chain

Each application can be master, servant or both. Configuration is usually in config/initialisers/coca.rb:

    # To act as a servant:

    Coca.delegate_to do |master|
      master.host = fq.domain.com or ip address or localhost
      master.port = optional unless localhost
      master.secret = "key"
    end
    
    # To act as a master:
    
    Coca.delegate_from do |servant|
      servant.host = fq.domain.com or ip address or localhost
      servant.secret = "key"
      servant.ttl = 3600
    end
    
You can have any number of links up and down. More than one look_up is unlikely and inefficient, but possible.
    
    # TTL can be set globally
    Coca.token_ttl = 86400
    
    # disable to not broadcast user changes or ignore incoming updates
    Coca.propagate_updates = true
    
    # disable to allow insecure requests in and out
    Coca.require_https = true
    
    # disable to omit reverse IP check on incoming requests and updates
    Coca.check_source = true

    # you may want to set this per environment
    Coca.cookie_domain = '.spanner.org'


### Delegating in a model

To start with coca is implemented as a devise strategy. Minimally:

    class User < ActiveRecord::Base
      devise :cocable
    end

The `:cocable` strategy will try token authentication and database authentication before it delegates to a master, so you don't need to declare those but you do have to support them in the database.


### Authenticating in the master

The syntax is the same as delegation, since we may also be passing auth up the chain. Here it matters which other strategies you apply because it is up to devise to authenticate against the supplied credentials. They would normally include at least database_authenticatable and token_authenticatable.

    class User < ActiveRecord::Base
      devise :database_authenticatable,
             :token_authenticatable,
             :cocable
    end


### Routing in the master

<!-- If your user class is called User, you can just mount Coca at /coca and the routes are set up for you.

    mount Coca::Engine => "/coca", :as => :coca

To handle other resource names you need to add some routes to the coca namespace. More documentation will follow if it ever seems like a good idea. -->


### Migrations

In the servant coca requires an `authentication_token` column that you may already have. All the other devise columns can be omitted unless you are supporting other strategies locally.

In the master coca has no special requirements but you still need the columns that support the strategies you offer. 


## Extending Coca

At heart coca is a simple remote authentication service: credentials are checked remotely and if they are found valid, user information is returned.

The data package that we return on successful auth is built by calling `as_json_on_authentication` on the user model in the coca master. By default it just returns uid and auth token, but you can override that method to return any data you like. Permissions, friends lists, recent messages, password replacement instructions: anything it makes sense to centralise can be held in the master and passed down to all the servant applications.


## Reminders and confirmations





## Propagating data

### Declaring delegated attributes



## Author

William Ross for spanner. Will at spanner dot org.

## Copyright

Copyright Spanner 2013. All rights reserved.

## License

Released under the MIT license.

