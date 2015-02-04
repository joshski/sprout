marked = require 'marked'
plastiq = require 'plastiq'
mediaEmbed = require 'media-embed'
h = plastiq.html

model = {
  document = {
    body = [
      {
        type = "markdown"
        content = [
          "## Kittens\n\n"
          "A kitten or kitty is a juvenile domesticated cat. A feline litter "
          "usually consists of two to five kittens. To survive, kittens need "
          "the care of their mother for the first several weeks o their life. "
          "Kittens are highly social animals and spend most of their waking "
          "hours playing and interacting with available companions."
        ].join("")
      }
      {
        type = "property_list"
        items = [
          { key = "Sunday", value = "happy" }
          { key = "Monday", value = "sad" }
        ]
      }
      {
        type = "image"
        src = "http://placekitten.com/g/96/96"
      }
      {
        type = "list"
        listStyle = "bullets"
        items = [
          { type = "markdown", content = "one" }
          { type = "markdown", content = "two" }
        ]
      }
      {
        type = "embed"
        url = "https://www.youtube.com/watch?v=_ZSbC09qgLI"
      }
      {
        type = "embed"
        url = "https://soundcloud.com/epitaph-records/this-wild-life-history"
      }
      {
        type = "embed"
        url = "https://twitter.com/VeryOldPics/status/560487536532156417"
      }
    ]
  }
}

editingItem = nil
edit (item) =
  if (editingItem @and editingItem.editing)
    delete (editingItem.editing)

  editingItem := item

  if (item)
    item.editing = true

types = {

  new_item = {

    name = 'New Item'

    create () =
      {
      }

    render (model, editing) =
      [
        h 'button' (
          {
            onclick () =
              model.type = 'markdown'
              model.content = ''
              edit (model)
          }

          '+ Markdown'
        )

        h 'button' (
          {
            onclick () =
              model.type = 'image'
              model.src = 'http://'
              edit (model)
          }

          '+ Image'
        )

        h 'button' (
          {
            onclick () =
              model.type = 'list'
              model.items = []
              edit (model)
          }

          '+ List'
        )

        h 'button' (
          {
            onclick () =
              model.type = 'property_list'
              model.items = []
              edit (model)
          }

          '+ Property List'
        )

        h 'button' (
          {
            onclick () =
              model.type = 'embed'
              model.url = 'http://'
              edit (model)
          }

          '+ Embed'
        )

      ]
  }

  list = {

    name = 'List'

    create () =
      {
        items = []
      }

    render (model, editing) =
      [
        h 'ul' (
          { class = model.listStyle }

          [
            item <- model.items
            h 'li' (renderItem (item, model.items, model))
          ]

          if (editing)
            h 'li' (
              h 'button' (
                {
                  onclick() =
                    model.items.push ({ type = 'new_item' })
                }
                '+ Add Item'
              )
            )
          else if (model.items.length == 0)
            h 'li' '[list]'
        )

        if (editing)
          h '.body-item-tools' (
            h 'select' { binding = [model, 'listStyle'] } (
              h 'option' { value = 'bullets' } 'Bullets'
              h 'option' { value = 'vertical' } 'Vertical'
              h 'option' { value = 'horizontal' } 'Horizontal'
            )
          )
      ]
  }

  property_list = {

    name = 'Property List'

    create () =
      {
        items = []
      }

    render (model, editing) =
      [
        h 'dl' (
          [
            item <- model.items
            [
              h 'dt' (
                if (editing)
                  [
                    h 'input' { binding = [item, 'key'] }
                  ]
                else
                  item.key
              )
              h 'dd' (
                if (editing)
                  [
                    h 'input' { binding = [item, 'value'] }
                    h 'button' {
                      onclick () =
                        model.items.splice(model.items.indexOf(item), 1)
                    } 'delete'
                  ]
                else
                  item.value
              )
            ]
          ]
        )
        if (editing)
          h 'button' (
            {
              onclick(e) =
                e.stopPropagation()
                model.items.push({ key = '', value = '' })
            }
            '+ Add Item'
          )
      ]

  }

  markdown = {

    name = 'Markdown'

    create () =
      {
        content = ""
      }

    render (model, editing) =
      if (editing)
        h 'textarea' {
          attributes = { autofocus = true }, binding = [model, 'content']
        }
      else
        html = marked(model.content)
        if (html.length == 0)
          html := '...'

        h.rawHtml '.markdown-content' (html)
  }

  image = {

    name = 'Image'

    create () =
      {
        src = ""
      }

    render (model, editing) =
      [
        if (editing)
          h '.edit' (
            h '.field' (
              h 'label' 'URL'
              h 'input.url' { type = 'text', binding = [model, 'src'] }
            )
          )

        h 'img' { src = model.src }
      ]
  }

  embed = {

    name = 'Embed'

    create () =
      {
        url = ""
      }

    render (model, editing) =
      [
        h '.edit' (
          if (editing)
            h '.field' (
              h 'label' 'URL'
              h 'input.url' { type = 'text', binding = [model, 'url'] }
            )
        )

        if (model.html)
          h.rawHtml('.embed-html', model.html)
        else
          fetch (fullfill) =
            mediaEmbed (model.url) @(err, embedElement, data)
              model.html = embedElement.innerHTML
              fullfill(model.html)

          p = @new Promise(fetch)
          h.promise (p) {
            pending = '...'
            fullfilled (html) = h.rawHtml('.embed-html', html.innerHTML)
          }
      ]
  }

}

renderDocument (document) =
  h '.document' (
    { class = { editing = editingItem :: Object } }
    h '.editing-overlay' {
      onclick () = edit (nil)
    }

    h '.body' (
      [
        item <- document.body
        renderItem (item, document.body)
      ]
      if (document.body.length == 0)
        h 'button' {
          onclick () =
            newItem = { type = 'new_item' }
            document.body.push(newItem)
            edit (newItem)
        } '+'
    )
  )

renderItem (item, list, parent) =
  index = list.indexOf (item)
  h ".body-item.#(item.type)" (
    {
      class = { editing = item.editing }
      onclick (e) =
        if (@not editingItem)
          edit (item)
          e.stopPropagation()
    }
    [
      h '.body-item-type' (types.(item.type).name)
      h '.editor' (
        if (item.editing)
          [
            h '.body-item-tools' (
              if (item.type != 'new_item')
                h 'button' {
                  onclick (e) =
                    e.stopPropagation()
                    edit (nil)
                } 'done'

              h 'button' {
                onclick (e) =
                  e.stopPropagation()
                  newItem = { type = 'new_item' }
                  list.splice(index, 0, newItem)
                  edit (newItem)
              } 'insert before'

              h 'button' {
                onclick (e) =
                  e.stopPropagation()
                  newItem = { type = 'new_item' }
                  list.splice(index + 1, 0, newItem)
                  edit (newItem)
              } 'add after'

              h 'button' {
                onclick (e) =
                  e.stopPropagation()
                  edit (nil)
                  list.splice(index, 1)
              } 'delete'

              if (parent)
                h 'button' {
                  onclick (e) =
                    e.stopPropagation()
                    edit (parent)
                } 'parent'

              if (index > 0)
                h 'button' {
                  onclick (e) =
                    e.stopPropagation()
                    above = list.(index - 1)
                    list.(index - 1) = item
                    list.(index) = above
                } 'move up'

              if (index < (list.length - 1))
                h 'button' {
                  onclick (e) =
                    e.stopPropagation()
                    below = list.(index + 1)
                    list.(index + 1) = item
                    list.(index) = below
                } 'move down'

            )
          ]
      )

      types.(item.type).render (item, item.editing)
    ]
  )

renderScreen (model) =
  h '.screen' (
    renderDocument (model.document, model.editing)
  )

dump (render) =
  @(model)
    h '.debug' (
      render (model)
      h 'pre.dump' (JSON.stringify (model, null, 4))
    )

plastiq.attach (document.body, dump (renderScreen), model)
