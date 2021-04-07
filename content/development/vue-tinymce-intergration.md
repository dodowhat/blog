---
title: "Vue 引入 TinyMCE 富文本编辑器"
date: 2020-05-07T14:44:38+08:00
draft: false
tags: ["VUE"]
---

本项目基于 [vue-cli](https://github.com/vuejs/vue-cli) 创建的项目实现。

将 TinyMCE 封装成一个 Vue Component，过程稍有些不优雅，因为官方提供的 tinymce-vue 功能不完善，不能直接使用。

## 准备工作

首先，通过 npm 安装 tinymce 和 tinymce-vue

```bash
npm install --save tinymce
npm install --save @tinymce/tinymce-vue
```

接着，是不优雅的部分:

* 复制 `node_modules/tinymce/skins` 目录到 `public/` 和 `public/js/` 目录下

* 访问 [https://www.tiny.cloud/get-tiny/language-packages/](https://www.tiny.cloud/get-tiny/language-packages/)
下载中文语言包，放入 `public/js/langs/` 目录下

* 为项目根目录设置一个别名，方便引用语言包，编辑 `vue.config.js`

```js
module.exports = {
  configureWebpack: {
    resolve: {
      alias: {
        '~': resolve('.')
      }
    }
  },
}
```

## 创建 Vue 组件

我将它命名为 `MyTinymce` 保存在 `src/components/MyTinymce/index.vue`

```vue
<template>
  <tinymce-vue
    v-model="content"
    :value="value"
    :init="init"
    @input="$emit('input', content)"
  />
</template>

<script>
  import TinymceVue from '@tinymce/tinymce-vue'
  import 'tinymce/tinymce'
  // 加载皮肤
  import 'tinymce/themes/silver'
  // 加载语言包
  import '~/public/js/langs/zh_CN.js'
  // 加载插件
  import 'tinymce/plugins/image'
  import 'tinymce/plugins/imagetools'

  const plugins = 'image imagetools axupimgs'

  const toolbar = 'undo redo | fontsizeselect | forecolor backcolor | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | axupimgs'

  function images_upload_handler(blobInfo, success, failure) {
    const file = blobInfo.blob()
    if (file.size / 1024 / 1024 > 2) {
      failure('请上传小于2M的图片')
      return
    }
    // upload file ...
  }

  const init = {
    language: 'zh_CN',
    plugins: plugins,
    menubar: false,
    toolbar: toolbar,
    images_upload_handler: images_upload_handler,
    imagetools_cors_hosts: ['example.com'], //如果图片链接是跨域的，需要将图片域名写入这个参数
    height: 800,
    branding: false
  }

  export default {
    name: 'MyTinymce',
    components: {
      TinymceVue
    },
    props: ['value'],
    data() {
      return {
        content: '',
        init: init
      }
    },
    mounted() {
      this.content = this.value
    },
    watch: {
      value(val) {
        this.content = val
      }
    }
  }
</script>
```

调用示例

```vue
<my-tinymce v-model="article.content" />
```

## 总结

本文主要实现了 TinyMCE 在 Vue 项目中的正常使用，后续可以将它打造成更灵活的基础组件。
比如将 `init` 作为 `props` 参数由外部传入等等，这里就不展开了。
