# Orbital Ring

This is a proof of concept for a front-end framework written in Ruby.
It is intended to work with ruby.wasm.

## Features

- Auto loading
- Rendering
- Event binding

## Usage

```html
<script defer
    src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi@2.5.0-2024-04-02-a/dist/browser.script.iife.js"></script>
<script type="text/ruby" src="https://cdn.jsdelivr.net/gh/ledsun/orbital_ring@0.0.1/orbital_ring.rb"></script>
```

### Auto loading

Load the Ruby script that defines the constants from the `app_root` directory.
For example, when the App class is called, `./app_root/app.rb` is load.

To enable auto loadding, execute the following function:

```ruby
OrbitalRing::Loader.setup
```

### Rendering

The `render` function can be used to render HTML using `erb.html` file as a template. For example:

```ruby
render :page, collection: pages
```

To use the `render` function, include `OrbitalRing::Renderer` module.

```ruby
include OrbitalRing::Renderer
```

Place the template file in the `app_root/templates` directory.

### Event binding

The `OrbitalRing::Routes.draw` function can be used to bind events like jQuery's `on` function. For example:

```ruby
OrbitalRing::Routes.draw do
  click '.confirm_button', to: ClickHandler, params: { view: view }
end
```

This is similar to the following example in jQuery:

```javascript
$('#app_root').on('click', '.confirm_button', function() {
  // Do something.
})
```

The HTML element to which the event is bound must be a child element of an HTML element whose id is `app_root`.
