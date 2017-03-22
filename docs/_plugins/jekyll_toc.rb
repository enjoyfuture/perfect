# 参考 https://github.com/toshimaru/jekyll-toc 和 https://github.com/dafi/jekyll-toc-generator 实现

require 'nokogiri'

module Jekyll
  module TableOfContents
    class Parser
      TOC_PREFIX = 'toc-'
      attr_reader :doc

      def initialize(html)
        @doc = Nokogiri::HTML::DocumentFragment.parse(html)
        @entries = parse_content
      end

      # 生成目录
      def build_toc
        toc = generateToc(@entries[:children], TOC_PREFIX)
      end

      # 加锚点后的内容
      def inject_anchors_into_html
        @doc.inner_html
      end

      def toc
        build_toc + inject_anchors_into_html
      end

      private

      # 循环遍历生成 html
      def generateToc(nodes, prefix)
        html = %Q{<ul class="menu menu-catalogue">\n}
        i = 0
        nodes.each do |node|
           # 为栏目对应的内容加锚点
           node[:content_node].add_previous_sibling(%Q{<a id="#{prefix}#{i + 1}" class="menu-anchor" href="##{prefix}#{i + 1}" aria-hidden="true"></a>})

           html << %Q{  <li>\n}
           html << %Q{    <a class="menu-title menu-header" href="##{prefix}#{i + 1}">#{node[:text]}</a>\n}
           if node[:children] && node[:children].length > 0
             subHtml = generateToc(node[:children], "#{prefix}#{i + 1}-");
             html << subHtml
           end
           html << %Q{  </li>\n}
           i += 1
        end
        html << "</ul>"
        html
      end

      #  解析目录
      #  根据 h1 到 h6 来动态生成目录结构，此算法实现过程比较简单，但构思巧妙，利用 Hash 对象生成了一个多叉树结构，
      #  算法实现：首先初始化根节点树，然后遍历每一个节点，比较当前节点与前一个节点，
      #  如果 header 的级别一样，则说明拥有相同的父节点，
      #  如果当前级别小于前一个，则作为前一个的孩子节点，如果当前级别大于前一个，则向上查找其祖先节点，并作为孩子节点加到该祖先节点下，
      #  遍历过程中以当前节点为基准，以上一个节点来作为比较对象，根据比较结果操作
      #  比如 ['h2', 'h2', 'h3', 'h4', 'h1', 'h1', 'h2', 'h3', 'h2', 'h4', 'h2', 'h5', 'h3', 'h3']，输出结果为

      #       root
      #       h2  h2  h1   h1
      #           h3       h2   h2   h2
      #           h4       h3   h4   h5 h3 h3

      def parse_content
        name = ''
        index = 0
        currentToc = {}

        # 初始化根节点
        entries = {
          level: 0,
          children: [],
          depth: 0,
          parent: nil,
          name: '',
          text: '',
          root: true
        }

        # 前一个元素 level
        prevLevel = 0

        nodes = doc.css('h1, h2, h3, h4, h5, h6')
        nodes.each do |node|
          text = node.text
          name = node.name
          level = 7 - name[1].to_i
          header_content = node.children.first # 取目录下第一个元素

          if header_content # 如果目录下有内容
            if index == 0
              # 初始化第一个元素
              toc = {
                level: level,
                children: [],
                depth: 1,
                parent: entries,
                name: name,
                text: text,
                content_node: header_content
              }
              entries[:children] << toc

             elsif
              currentLevel = 7 - name[1].to_i
              if currentLevel == prevLevel  # 相等的话
                toc = {
                  level: currentLevel,
                  children: [],
                  depth: currentToc[:depth],
                  parent: currentToc[:parent],
                  name: name,
                  text: text,
                  content_node: header_content
                }
                currentToc[:parent][:children] << toc

              elsif currentLevel < prevLevel # 如果当前级别小于前一个
                toc = {
                  level: currentLevel,
                  children: [],
                  depth: currentToc[:depth] + 1,
                  parent: currentToc,
                  name: name,
                  text: text,
                  content_node: header_content
                }
                currentToc[:children] << toc

              else # 如果当前级别大于前一个 查找祖先节点
                ancestor = currentToc[:parent]
                while ancestor[:level] <= currentLevel && ancestor[:root] == nil do
                   ancestor = ancestor[:parent]
                end

                toc = {
                  level: currentLevel,
                  children: [],
                  depth: ancestor[:depth] + 1,
                  parent: ancestor,
                  name: name,
                  text: text,
                  content_node: header_content
                }
                ancestor[:children] << toc
              end
            end

            index += 1
            currentToc = toc
            prevLevel = level
          end
        end

        entries
      end
    end
  end
end

module Jekyll
  module TableOfContentsFilter
    # 定义 方法解析目录结构，需要在页面中设置 toc
    def toc(html)
      return html unless page['toc']

      ::Jekyll::TableOfContents::Parser.new(html).toc
    end

    private

    def page
      @context.registers[:page]
    end
  end
end

Liquid::Template.register_filter(Jekyll::TableOfContentsFilter)
