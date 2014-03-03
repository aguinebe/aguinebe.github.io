---
layout: page
title: Welcome to Tableau Tips!
tagline: 
---
{% include JB/setup %}

Welcome to Tableau Tips!

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
