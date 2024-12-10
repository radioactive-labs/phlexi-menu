require "test_helper"

module Phlexi
  class FieldTest < Minitest::Test
    class User
      # include ActiveModel::Model
      attr_accessor :name, :email, :age, :admin, :profile

      def self.human_attribute_name(attr, options = {})
        attr.to_s.humanize
      end

      def self.validators_on(attr)
        []
      end
    end

    class Profile
      # include ActiveModel::Model
      attr_accessor :bio, :avatar
    end

    def setup
      profile = Profile.new
      profile.bio = "A developer"

      @user = User.new
      @user.name = "John Doe"
      @user.email = "john@example.com"
      @user.age = 30
      @user.admin = true
      @user.profile = profile
    end

    def test_basic_field_value_inference
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      # Test string field
      name_field = namespace.field(:name)
      assert_equal "John Doe", name_field.value
      assert_equal :string, name_field.inferred_field_type

      # Test numeric field
      age_field = namespace.field(:age)
      assert_equal 30, age_field.value
      assert_equal :integer, age_field.inferred_field_type

      # Test boolean field
      admin_field = namespace.field(:admin)
      assert_equal true, admin_field.value
      assert_equal :boolean, admin_field.inferred_field_type
    end

    def test_nested_object_handling
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      profile_namespace = namespace.nest_one(:profile)
      bio_field = profile_namespace.field(:bio)

      assert_equal "A developer", bio_field.value
      assert_equal "user_profile_bio", bio_field.dom.id
      assert_equal "user[profile][bio]", bio_field.dom.name
    end

    def test_dom_id_generation
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      field = namespace.field(:email)

      assert_equal "user_email", field.dom.id
      assert_equal "user[email]", field.dom.name
      assert_equal "john@example.com", field.dom.value
    end

    def test_email_field_type_inference
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      email_field = namespace.field(:email)
      assert_equal :email, email_field.inferred_string_field_type
    end

    def test_password_field_type_inference
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      password_field = namespace.field(:password)
      assert_equal :password, password_field.inferred_string_field_type

      encrypted_password_field = namespace.field(:encrypted_password)
      assert_equal :password, encrypted_password_field.inferred_string_field_type

      password_digest_field = namespace.field(:password_digest)
      assert_equal :password, password_digest_field.inferred_string_field_type
    end

    def test_label_generation
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      field = namespace.field(:email)
      assert_equal "Email", field.label

      labelled_field = namespace.field(:labelled_email, label: "Contact Email")
      assert_equal "Contact Email", labelled_field.label
    end

    def test_field_options
      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: @user
      )

      field = namespace.field(:email,
        placeholder: "Enter email",
        hint: "We'll never share your email",
        description: "Your primary contact email")

      assert_equal "Enter email", field.placeholder
      assert_equal "We'll never share your email", field.hint
      assert_equal "Your primary contact email", field.description
      assert field.has_hint?
      assert field.has_description?
    end

    def test_hash_object_support
      hash_user = {
        name: "Jane Doe",
        email: "jane@example.com",
        profile: {
          bio: "A designer"
        }
      }

      namespace = Phlexi::Menu::Structure::Namespace.root(
        :user,
        builder_klass: Phlexi::Menu::Builder,
        object: hash_user
      )

      assert_equal "Jane Doe", namespace.field(:name).value
      assert_equal "A designer", namespace.nest_one(:profile).field(:bio).value
    end
  end
end
