# Mailer Extension for Radiant

[![Build Status](https://secure.travis-ci.org/radiant/radiant-mailer-extension.png)](http://travis-ci.org/radiant/radiant-mailer-extension)

The Mailer extension enables form mail on a page.

## Usage

You can define email templates using pages parts (email, and/or email_html).
You configure the recipients and other Mailer settings in a "mailer" part:

    subject: From the website of Whatever
    from: noreply@example.com
    redirect_to: /contact/thank-you
    recipients:
      - one@one.com
      - two@two.com

The following tags are available to help you build the form:

    <r:mailer:form name=""> ... </r:mailer:form>
    <r:mailer:text name="" />
    <r:mailer:password name="" />
    <r:mailer:reset name="" />
    <r:mailer:checkbox name="" />
    <r:mailer:radio name="" />
    <r:mailer:file name="" />
    <r:mailer:radiogroup name=""> ... </r:mailer:radiogroup>
    <r:mailer:select name=""> ... </r:mailer:select>
    <r:mailer:date_select name=""/>
    <r:mailer:textarea name=""> ... </r:mailer:textarea>
    <r:mailer:option name="" />
    <r:mailer:submit name="" />
    <r:mailer:image name="" />
    <r:mailer:submit_placeholder />

When processing the form (in email and email_html), the following tags are
available:

    <r:mailer:get name="" />
    <r:mailer:get_each name=""> ... </r:mailer:get_each>
      <r:mailer:index />

Simple example of a form:

    <r:mailer:form>
     <r:mailer:hidden name="subject" value="Email from my Radiant site!" /> <br/>
      Name:<br/>
     <r:mailer:text name="name" /> <br/>
      Message:<br/>
     <r:mailer:textarea name="message" /> <br/>
     <r:mailer:submit name="Send" />
    </r:mailer:form>

### Required fields

You can specify fields which must be populated or the form will be invalid and will redisplay the page with an error informing the user to populate those fields.

Simple example of a required field:

    <r:mailer:form>
     ...
      Name:<br/>
     <r:mailer:text name="name" required="true"/> <br/>
     ...
     <r:mailer:submit name="Send" />
    </r:mailer:form>

Simple example of a required field with user-defined message:

    <r:mailer:form>
     ...
      Name:<br/>
     <r:mailer:text name="name" required="should not be blank"/> <br/>
     ...
     <r:mailer:submit name="Send" />
    </r:mailer:form>

You can also specify fields which must be validated 'as_email' (i.e. a@b.com).

Simple example of a required field with email address validation:

    <r:mailer:form>
     ...
      Reply-To:<br/>
     <r:mailer:text name="reply_email" required="as_email"/> <br/>
     ...
     <r:mailer:submit name="Send" />
    </r:mailer:form>

You can also specify fields which must be validated as defined regexp (i.e. /^\d{2}\.\d{2}\.\d{4}\$/ for date dd.mm.yyyy).


Simple example of a required field with regexp validation:

    <r:mailer:form>
     ...
      Birthday:<br/>
     <r:mailer:text name="birthday" required="/^\d{2}\.\d{2}\.\d{4}\$/"/> <br/>
     ...
     <r:mailer:submit name="Send" />
    </r:mailer:form>

Finally, you can put all field validations in the "mailer" part:

    subject: From the website of Whatever
    from: noreply@example.com
    redirect_to: /contact/thank-you
    recipients:
      - one@one.com
    required:
      name: "true"
      email: as_email
      message: "true"

The field names above are "name," "email," and "message." Note the quotation marks around true values. If you do your field validations this way, Mailer will ignore any validations you attempt through your radius tags. This method of validation keeps Mailer from adding hidden inputs to keep track of required fields. See the caveat below.


### Spam blocking

#### No Links

You can specify which fields may not contain anything that looks like a link in the "mailer" part. For example:

    subject: From the website of Whatever
    from: noreply@example.com
    redirect_to: /contact/thank-you
    recipients:
      - one@one.com
    disallow_links:
      - comments
      - questions

The comments and questions fields would throw an error if the user or a spam bot entered the following phrases: "www", "&amp;", "http:", "mailto:", "bcc:", "href", "multipart", "[url", or "Content-Type:".

#### Hidden field must be blank

You can also include one field on your form that must be left blank. If anyone enters something in the field, the field throws an error. The tactic here is to hide the field from human readers, but to leave the field visible to spam bots. Here is how you would edit the "mailer" part to implement this:

    subject: From the website of Whatever
    from: noreply@example.com
    redirect_to: /contact/thank-you
    recipients:
      - one@one.com
    leave_blank: your_field_name

"your_field_name" is the name of the field you want to hide. It is up to you to hide the field when you construct your form. I would recommend against using a traditional hidden input field. Use style="display:none" instead.

#### Blocked Words

You can also add specific words to the mail config, which if present in any of the input fields, will throw an error.  This way if you get hit by a barage of say, 'imabot@spammer.net', you just add that term to the block list.  Here is how you would edit the "mailer" part to implement this:

    subject: From the website of Whatever
    from: noreply@mydomain.com
    redirect_to: /contact/thank-you
    max_filesize: 100000
    recipients:
      - one@one.com
      - two@two.com
    block_words:
      - spammer
      - badword
      - imabot

### File attachments

In many cases it is desirable to limit the maximum size of a file that may be uploaded. This is set as the max_filesize attribute for mailers in the mailer page part. Any file included in the form will have the limit imposed. Following is a simple example mailer part that includes a file size limit of 100,000 bytes:

    subject: From the website of Whatever
    from: noreply@mydomain.com
    redirect_to: /contact/thank-you
    max_filesize: 100000
    recipients:
      - one@one.com
      - two@two.com

The following is a simple form that might be used to submit a file for the above configuration:

    <r:mailer:form name="contact">
        Type your message: <r:mailer:text name="themessage" /> <br/>
        Select a file: <r:mailer:file name="thefile" /> <br/>
        <r:mailer:submit value="submit"/>
    </r:mailer:form>

If a user does not select a file the other form contents will still be e-mailed. The `<r:mailer:get name="foo" />` (with `<r:mailer:file name="foo" />`) will provide the uploaded file name.

If you are using email or email_html parts then the `<r:mailer:get name="" />` tag can be used to retrieve the name of the uploaded file. If no file was uploaded "" will be returned.

### Submit placeholder

If you wish to show that activity is taking place during submission you may use the `<r:mailer:submit_placeholder />` tag in your form. This will insert a hidden div with the contents of the submit_placeholder page part. The div will be displayed when the user clicks any submit button.

### User-provided Configuration

Sometimes, rather than explicitly configuring the recipients and such in the mailer part, you'd rather have them passed in by the person submitting the form. Mailer supports this by allowing you to specify a form field to pull the value from:

    from_field: my_form_field_that_contains_the_from_email_address

Then you just have to add that field to your mailer form and you're all set.

This is supported for the from (from_field), recipients (recipients_field) and reply_to (reply_to_field) properties.

## Enabling action_mailer

In environment.rb you'll probably need to change:

    config.frameworks -= [ :action_mailer ]

to:

    config.frameworks -= []

## Updating from the older mailer extension

If you get this error "The single-table inheritance mechanism failed to locate the subclass: 'MailerPage'.", run `rake:radiant:extensions:mailer:migrate`. This will change all pages with a MailerPage classname into regular pages. Second, your 'config' page part has to be renamed to 'mailer', and the first two YAML levels should be deleted (see instructions above).

If you are getting a stack level too deep error, it may be caused by using `<r:mailer:get />` in your 'mailer' part. Use the from_field or other options to get to the email adress that was posted (see User-provided configuration).

## Caveats

Relative urls will almost certainly not work if the mailer fails validation. Solution? Only use absolute urls.

Unless you set up the field validations in the "mailer" part, validation will be implemented via easily spoofable HTML attributes. Think of them of more like guidelines in that case.

## Initial History

Created by: M@ McCray - mattmccray.com
  Version: 0.2.1
  Contact: mmccray@elucidata.net

Ported to 'mental' by: Sean Cribbs - seancribbs.com
  Version: 0.1
  Contact: seancribbs@gmail.com

Seriously restructured by: Nathaniel Talbott - terralien.com
  Version: 0.2
  Contact: nathaniel@terralien.com
  Work sponsored by: Ignite Social Media, http://ignitesocialmedia.com/

## [Contributors](https://github.com/radiant/radiant-mailer-extension/graphs/contributors)
