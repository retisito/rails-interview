# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js", preload: true
pin "@hotwired/stimulus", to: "https://unpkg.com/@hotwired/stimulus@3.2.1/dist/stimulus.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"