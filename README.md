This is a basic application showing how to get started with the Xero's official [xero-ruby](https://github.com/XeroAPI/xero-ruby) SDK

# Example deployment

https://xero-spike.herokuapp.com/

# Getting Started
### 1) Make sure you have at least Ruby 2.7
```bash
ruby -v
ruby 2.7.0
```

### 2) Create an app in Xero's developer portal
https://developer.xero.com/myapps/

### 3) Decide what `scopes` your application needs
https://developer.xero.com/documentation/oauth2/scopes

### 4) Clone app and rename `sample.env` to `.env` and replace with the **4 required parameters**
```bash
$ git clone https://github.com/pdeka/xero-spike.git
$ cd xero-spike/
$ mv sample.env .env
```
Replace `CLIENT_ID`, `CLIENT_SECRET`, `REDIRECT_URI` & `SCOPES` with your unique parameters

```bash
$ source .env
```

### 5) Install dependencies & run the app
```bash
$ bundle install
$ bundle exec ruby xero_app.rb
```

> Visit `http://localhost:4567/` and start exploring the code in your editor of choice 🥳

Checkout `xero_app.rb` for all the sample code you need to get started for your own app


## Xero API endpoints

https://developer.xero.com/documentation/api/accounting/organisation/#overview

## Getting started guide with details on how to be a partner and have your app in the Xero app store

https://developer.xero.com/documentation/getting-started-guide

